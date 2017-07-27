/*
 * Copyright (C) 2017 TypeFox and others.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
 */
package io.typefox.yang.diagram

import io.typefox.sprotty.api.LayoutOptions
import io.typefox.sprotty.api.SCompartment
import io.typefox.sprotty.api.SEdge
import io.typefox.sprotty.api.SGraph
import io.typefox.sprotty.api.SLabel
import io.typefox.sprotty.api.SModelElement
import io.typefox.sprotty.api.SModelRoot
import io.typefox.sprotty.api.SNode
import io.typefox.sprotty.server.xtext.IDiagramGenerator
import io.typefox.yang.yang.AbstractModule
import io.typefox.yang.yang.Augment
import io.typefox.yang.yang.Base
import io.typefox.yang.yang.Case
import io.typefox.yang.yang.Choice
import io.typefox.yang.yang.Container
import io.typefox.yang.yang.Grouping
import io.typefox.yang.yang.Identity
import io.typefox.yang.yang.Import
import io.typefox.yang.yang.Include
import io.typefox.yang.yang.Key
import io.typefox.yang.yang.Leaf
import io.typefox.yang.yang.LeafList
import io.typefox.yang.yang.Module
import io.typefox.yang.yang.Prefix
import io.typefox.yang.yang.SchemaNode
import io.typefox.yang.yang.SchemaNodeIdentifier
import io.typefox.yang.yang.Statement
import io.typefox.yang.yang.Submodule
import io.typefox.yang.yang.Type
import io.typefox.yang.yang.Typedef
import io.typefox.yang.yang.Uses
import io.typefox.yang.yang.impl.AugmentImpl
import io.typefox.yang.yang.impl.CaseImpl
import io.typefox.yang.yang.impl.ChoiceImpl
import io.typefox.yang.yang.impl.ContainerImpl
import io.typefox.yang.yang.impl.GroupingImpl
import io.typefox.yang.yang.impl.IdentityImpl
import io.typefox.yang.yang.impl.ListImpl
import io.typefox.yang.yang.impl.ModuleImpl
import io.typefox.yang.yang.impl.SubmoduleImpl
import io.typefox.yang.yang.impl.TypedefImpl
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.apache.log4j.Logger
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.util.CancelIndicator

class YangDiagramGenerator implements IDiagramGenerator {
	static val LOG = Logger.getLogger(YangDiagramGenerator)

	static val COMPOSITION_EDGE_TYPE = 'composition'
	static val STRAIGHT_EDGE_TYPE = 'straight'
	static val DASHED_EDGE_TYPE = 'dashed'
	static val IMPORT_EDGE_TYPE = 'import'
	static val USES_EDGE_TYPE = 'uses'
	static val AUGMENTS_EDGE_TYPE = 'augments'

	var Map<Statement, SModelElement> elementIndex
	var List<()=>void> postProcesses

	var SGraph diagramRoot

	override generate(Resource resource, Map<String, String> options, CancelIndicator cancelIndicator) {
		val content = resource.contents.head
		if (content instanceof AbstractModule) {
			LOG.info("Generating diagram for input: '" + resource.URI.lastSegment + "'")
			return generateDiagram(content, cancelIndicator)
		}
		return null
	}

	def SModelRoot generateDiagram(AbstractModule module, CancelIndicator cancelIndicator) {
		elementIndex = new HashMap
		postProcesses = new ArrayList
		diagramRoot = new SGraph => [
			type = 'graph'
			id = 'yang'
			children = new ArrayList<SModelElement>
			layoutOptions = new LayoutOptions [
				HAlign = 'left'
				HGap = 10.0
				VGap = 0.0
				paddingLeft = 0.0
				paddingRight = 0.0
				paddingTop = 0.0
				paddingBottom = 0.0
			]
		]

		val rootChildren = createChildElements(diagramRoot, diagramRoot, #[module])
		diagramRoot.children.addAll(rootChildren)
		postProcessing()
		return diagramRoot
	}

	/**
	 * @param viewParentElement SModelElement
	 * @param modelParentElement SModelElement
	 * @param statements List<Statement>
	 */
	protected def List<SModelElement> createChildElements(SModelElement viewParentElement,
		SModelElement modelParentElement, List<Statement> statements) {
		val rootChildren = new ArrayList()
		for (statement : statements) {
			var SModelElement element = null
			element = generateElement(statement, viewParentElement, modelParentElement)
			if (element !== null) {
				val eid = element.id
				LOG.debug("CREATED ELEMENT FOR statement:" + statement.toString + " WITH ID " + eid)
				if (elementIndex.filter[k, v|v.id == eid].size > 0) {
					LOG.debug(eid + " ALREADY EXISTS!!!")
				}

				elementIndex.put(statement, element)
				rootChildren.add(element)
			}
		}
		return rootChildren
	}

	protected def dispatch SModelElement generateElement(Module moduleStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		val prefix = moduleStmt.substatements.filter(Prefix).head
		val moduleElement = createModule(moduleStmt.name, prefix.prefix)
		initModule(moduleElement, findClass(moduleStmt), moduleStmt.name, moduleStmt)
	}

	protected def dispatch SModelElement generateElement(Submodule submoduleStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		val moduleElement = createModule(submoduleStmt.name)
		initModule(moduleElement, findClass(submoduleStmt), submoduleStmt.name, submoduleStmt)
	}

	protected def dispatch SModelElement generateElement(Container containerStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		return createClassElement(containerStmt, viewParentElement, modelParentElement, COMPOSITION_EDGE_TYPE)
	}

	protected def dispatch SModelElement generateElement(io.typefox.yang.yang.List listStmt,
		SModelElement viewParentElement, SModelElement modelParentElement) {
		return createClassElement(listStmt, viewParentElement, modelParentElement, COMPOSITION_EDGE_TYPE)
	}

	protected def dispatch SModelElement generateElement(Key keyStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		if (modelParentElement instanceof SCompartment) {
			val keyReferences = keyStmt.references
			postProcesses.add([
				(keyReferences).forEach [ keyReference |
					val leafElement = elementIndex.get(keyReference.node) as SLabel
					val label = leafElement.text
					leafElement.text = '* ' + label
				]
			])
		}
		return null
	}

	protected def dispatch SModelElement generateElement(Grouping groupingStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		createClassElement(groupingStmt, viewParentElement, modelParentElement, null)
	}

	protected def dispatch SModelElement generateElement(Typedef typedefStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		createClassElement(typedefStmt, viewParentElement, modelParentElement, null)
	}

	protected def dispatch SModelElement generateElement(Identity identityStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		val base = identityStmt.substatements.filter(Base).head
		if (base === null)
			return createClassElement(identityStmt, viewParentElement, modelParentElement, USES_EDGE_TYPE)
		else {
			postProcesses.add([
				val identityElement = createClassElement(identityStmt, viewParentElement, modelParentElement, null)
				modelParentElement.children.add(identityElement)
				val baseIdentityElement = elementIndex.get(base.reference)
				if (baseIdentityElement !== null)
					modelParentElement.children.add(
						createEdge(baseIdentityElement, identityElement, STRAIGHT_EDGE_TYPE))
			])
			return null
		}
	}

	protected def dispatch SModelElement generateElement(Augment augmentStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		val SchemaNodeIdentifier schemaNodeIdentifier = augmentStmt.path
		val node = NodeModelUtils.getNode(schemaNodeIdentifier)
		val path = node.leafNodes.filter[!hidden].map[text].join
		val targetNode = schemaNodeIdentifier.schemaNode
		val augmentElementId = viewParentElement.id + '-' + targetNode.name + '-augmentation'
		var SModelElement augmentElement = null
		var sameAugmentTarget = elementIndex.values.findFirst [ element |
			element.id == augmentElementId
		]

		if (sameAugmentTarget !== null) {
			val sameAugmentTargetCompartment = sameAugmentTarget.children.findFirst [ element |
				element.type == 'comp:comp'
			]
			sameAugmentTargetCompartment.children.addAll(
				createChildElements(sameAugmentTarget, sameAugmentTargetCompartment, augmentStmt.substatements))
		} else {
			augmentElement = createClassElement(augmentStmt, path, augmentElementId, viewParentElement,
				modelParentElement, COMPOSITION_EDGE_TYPE, findClass(augmentStmt))

			postProcesses.add([
				val targetElement = elementIndex.get(targetNode)
				if (targetElement !== null) {
					modelParentElement.children.add(
						createEdge(elementIndex.get(augmentStmt), targetElement, AUGMENTS_EDGE_TYPE))
				}
			])
		}

		return augmentElement
	}

	protected def dispatch SModelElement generateElement(Choice choiceStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		if (modelParentElement instanceof SNode) {
			val choiceNode = createClassElementWithHeader(viewParentElement.id, choiceStmt.name, 'choice')
			choiceNode.source = choiceStmt
			val SEdge toChoiceEdge = createEdge(viewParentElement, choiceNode, DASHED_EDGE_TYPE)
			modelParentElement.children.add(toChoiceEdge)
			if (choiceNode !== null) {
				choiceStmt.substatements.forEach([
					if (!(it instanceof Case)) {
						if (it instanceof SchemaNode) {
							val caseElement = createClassElementWithHeader(choiceNode.id + "-" + it.name + "-case",
								it.name, 'case')
							caseElement.source = it
							val caseCompartment = createClassMemberCompartment(caseElement.id)
							caseElement.children.add(caseCompartment)
							modelParentElement.children.add(caseElement)
							val toCaseEdge = createEdge(choiceNode, caseElement, DASHED_EDGE_TYPE)
							modelParentElement.children.add(toCaseEdge)

							caseCompartment.children.addAll(createChildElements(caseElement, caseCompartment, #[it]))

							modelParentElement.children.addAll(
								createChildElements(caseElement, modelParentElement, #[it]))
						}
					} else {
						modelParentElement.children.add(
							createTypedElementWithEdge(modelParentElement, choiceNode, (it as SchemaNode), 'case',
								DASHED_EDGE_TYPE))
					}
				])
				choiceNode.layoutOptions = new LayoutOptions [
					HAlign = 'center'
					paddingLeft = 25.0
					paddingRight = 25.0
					paddingTop = 20.0
					paddingBottom = 20.0
					paddingFactor = 3.0
				]
				return choiceNode
			}
		}
	}

	protected def dispatch SModelElement generateElement(Case caseStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		val caseNode = createTypedElementWithEdge(modelParentElement, viewParentElement, caseStmt, 'case',
			DASHED_EDGE_TYPE)
		if (caseNode !== null) {
			caseNode.layoutOptions = new LayoutOptions [
				HAlign = 'center'
				paddingBottom = 10.0
				paddingTop = 10.0
				paddingLeft = 8.0
				paddingRight = 8.0
			]
		}
		return caseNode
	}

	protected def dispatch SModelElement generateElement(Uses usesStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		if (modelParentElement instanceof SCompartment) {
			val SLabel memberElement = configSElement(SLabel,
				viewParentElement.id + '-uses-' + usesStmt.grouping.node.name, 'text')
			memberElement.text = 'uses ' + usesStmt.grouping.node.name
			return memberElement
		} else {
			postProcesses.add([
				val groupingElement = elementIndex.get(usesStmt.grouping.node)
				// is there a grouping element in this module? If not its usage relates to an external module grouping
				if (groupingElement !== null)
					modelParentElement.children.add(createEdge(viewParentElement, groupingElement, USES_EDGE_TYPE))
			])
			return null
		}
	}

	protected def dispatch SModelElement generateElement(Import importStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		val prefix = importStmt.substatements.filter(Prefix).head
		val module = createModule(importStmt.module.name, prefix.prefix)

		diagramRoot.children.add(module)

		postProcesses.add([
			diagramRoot.children.add(createEdge(module, modelParentElement, IMPORT_EDGE_TYPE))
		])

		return null
	}

	protected def dispatch SModelElement generateElement(Include includeStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		val submodule = includeStmt.module
		val module = createModule(submodule.name)
		return module
	}

	protected def dispatch SModelElement generateElement(Leaf leafStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		createClassMemberElement(leafStmt, viewParentElement, modelParentElement)
	}

	protected def dispatch SModelElement generateElement(LeafList leafListStmt, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		createClassMemberElement(leafListStmt, viewParentElement, modelParentElement)
	}

	protected def dispatch SModelElement generateElement(EObject node, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		return null
	}

	protected def SNode initModule(SNode moduleElement, String tag, String name, Statement moduleStmt) {
		// Module node
		val moduleNode = configSElement(YangNode, moduleElement.id + '-node', 'class')
		moduleNode.layout = 'vbox'
		moduleNode.layoutOptions = new LayoutOptions [
			paddingLeft = 0.0
			paddingRight = 0.0
			paddingTop = 0.0
			paddingBottom = 0.0
		]
		moduleNode.cssClass = 'moduleNode'
		moduleNode.source = moduleStmt

		moduleNode.children.add(createClassHeader(moduleNode.id, findTag(moduleStmt), name))

		moduleElement.children.add(moduleNode)
		moduleElement.children.addAll(createChildElements(moduleNode, moduleElement, moduleStmt.substatements))

		return moduleElement
	}

	protected def <E extends SModelElement> E configSElement(Class<E> elementClass, String idStr, String typeStr) {
		elementClass.constructor.newInstance => [
			id = idStr
			type = findType(it) + ':' + typeStr
			children = new ArrayList<SModelElement>
		]
	}

	protected def YangHeaderNode createClassHeader(String id, String tag, String name) {
		val classHeader = configSElement(YangHeaderNode, id + '-header', 'classHeader')
		classHeader.layout = 'hbox'
		classHeader.layoutOptions = new LayoutOptions [
			paddingLeft = 8.0
			paddingRight = 8.0
			paddingTop = 8.0
			paddingBottom = 8.0
		]
		classHeader.children = #[
			new SLabel [ l |
				l.type = "label:classTag"
				l.id = classHeader.id + '-tag'
				l.text = tag
			],
			new SLabel [ l |
				l.type = "label:classHeader"
				l.id = classHeader.id + '-header-label'
				l.text = name
			]
		]
		return classHeader
	}

	protected def SNode createModule(String name) {
		// Module
		val moduleElement = configSElement(SNode, name, 'module')
		moduleElement.layout = 'vbox'
		moduleElement.layoutOptions = new LayoutOptions [
			paddingTop = 5.0
			paddingBottom = 5.0
			paddingLeft = 5.0
			paddingRight = 5.0
		]

		// Module label
		val SLabel moduleLabel = configSElement(SLabel, moduleElement.id + '-label', 'heading')
		moduleLabel.text = name
		moduleElement.children.add(moduleLabel)
		return moduleElement
	}

	protected def SNode createModule(String name, String prefix) {
		createModule(prefix + ':' + name)
	}

	protected def SModelElement createClassMemberElement(SchemaNode statement, SModelElement viewParentElement,
		SModelElement modelParentElement) {
		if (modelParentElement instanceof SCompartment) {
			val SLabel memberElement = configSElement(SLabel, viewParentElement.id + '-' + statement.name, 'text')
			val Type type = statement.substatements.filter(Type).head
			val String nameAddition = if(statement instanceof LeafList) '[]' else ''
			memberElement.text = statement.name + nameAddition + ': ' + type.typeRef.builtin
			return memberElement
		}
	}

	protected def SModelElement createClassElement(SchemaNode statement, SModelElement viewParentElement,
		SModelElement modelParentElement, String edgeType) {
		val cssClass = findClass(statement)
		createClassElement(statement, statement.name, viewParentElement.id + '-' + cssClass + '-' + statement.name,
			viewParentElement, modelParentElement, edgeType, cssClass)
	}

	protected def SModelElement createClassElement(Statement statement, String label, String id,
		SModelElement viewParentElement, SModelElement modelParentElement, String edgeType, String cssClass) {
		if (modelParentElement instanceof SNode) {
			val classElement = configSElement(YangNode, id, 'class')
			classElement.layout = 'vbox'
			classElement.layoutOptions = new LayoutOptions [
				paddingLeft = 0.0
				paddingRight = 0.0
				paddingTop = 0.0
				paddingBottom = 0.0
			]
			classElement.cssClass = cssClass
			classElement.source = statement

			classElement.children.add(createClassHeader(classElement.id, findTag(statement), label))

			// add class members to compartment element
			val compartment = configSElement(SCompartment, classElement.id + '-compartment', 'comp')
			compartment.layout = 'vbox'
			compartment.layoutOptions = new LayoutOptions [
				paddingLeft = 12.0
				paddingRight = 12.0
				paddingTop = 12.0
				paddingBottom = 12.0
				VGap = 2.0
			]

			compartment.children.addAll(createChildElements(classElement, compartment, statement.substatements))
			classElement.children.add(compartment)

			// add composition elements 
			modelParentElement.children.addAll(
				createChildElements(classElement, modelParentElement, statement.substatements))

			if (edgeType !== null) {
				val SEdge compositionEdge = configSElement(SEdge,
					viewParentElement.id + '2' + classElement.id + '-edge', edgeType)
				compositionEdge.sourceId = viewParentElement.id
				compositionEdge.targetId = classElement.id
				modelParentElement.children.add(compositionEdge)
			}

			return classElement
		}
	}

	protected def SNode createTypedElementWithEdge(SModelElement modelParentElement, SModelElement viewParentElement,
		SchemaNode stmt, String type, String edgeType) {
		if (modelParentElement instanceof SNode) {

			val name = stmt.name

			val classElement = createClassElementWithHeader(viewParentElement.id, name, type)

			// add class members to compartment element
			val compartment = createClassMemberCompartment(classElement.id)
			compartment.children.addAll(createChildElements(classElement, compartment, stmt.substatements))
			classElement.children.add(compartment)

			modelParentElement.children.addAll(
				createChildElements(classElement, modelParentElement, stmt.substatements))

			val SEdge edge = createEdge(viewParentElement, classElement, edgeType)
			modelParentElement.children.add(edge)

			return classElement
		}
	}

	protected def SCompartment createClassMemberCompartment(String id) {
		val compartment = configSElement(SCompartment, id + '-compartment', 'comp')
		compartment.layout = 'vbox'
		compartment.layoutOptions = new LayoutOptions [
			paddingFactor = 1.0
			paddingLeft = 0.0
			paddingRight = 0.0
			paddingTop = 0.0
			paddingBottom = 0.0
		]
		return compartment
	}

	protected def YangNode createClassElementWithHeader(String id, String name, String type) {
		val classElement = configSElement(YangNode, id + '-' + name + '-' + type, type)
		classElement.layout = 'vbox'

		val headingContainer = configSElement(SCompartment, classElement.id + '-heading', 'comp')
		headingContainer.layout = 'vbox'
		headingContainer.layoutOptions = new LayoutOptions [
			paddingFactor = 1.0
			paddingLeft = 0.0
			paddingRight = 0.0
			paddingTop = 0.0
			paddingBottom = 0.0
		]

		val heading = configSElement(SLabel, headingContainer.id + '-label', 'heading')
		heading.text = name
		headingContainer.children.add(heading)
		classElement.children.add(headingContainer)
		return classElement
	}

	protected def SEdge createEdge(SModelElement fromElement, SModelElement toElement, String edgeType) {
		val SEdge edge = configSElement(SEdge, fromElement.id + '2' + toElement.id + '-edge', edgeType)
		edge.sourceId = fromElement.id
		edge.targetId = toElement.id
		return edge
	}

	protected def String findClass(Statement statement) {
		switch statement {
			TypedefImpl: 'typedef'
			ChoiceImpl: 'choice'
			CaseImpl: 'case'
			AugmentImpl: 'augment'
			ListImpl: 'list'
			ContainerImpl: 'container'
			ModuleImpl: 'module'
			SubmoduleImpl: 'submodule'
			GroupingImpl: 'grouping'
			IdentityImpl: 'identity'
			default: ''
		}
	}

	protected def String findTag(Statement statement) {
		switch statement {
			AugmentImpl: 'A'
			ListImpl: 'L'
			ContainerImpl: 'C'
			ModuleImpl: 'M'
			SubmoduleImpl: 'S'
			GroupingImpl: 'G'
			TypedefImpl: 'T'
			IdentityImpl: 'I'
			default: ''
		}
	}

	protected def String findType(SModelElement element) {
		switch element {
			SNode: 'node'
			SLabel: 'label'
			SCompartment: 'comp'
			SEdge: 'edge'
			default: 'dontknow'
		}
	}

	protected def void postProcessing() {
		postProcesses.forEach[process|process.apply]
	}

}
