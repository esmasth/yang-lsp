package io.typefox.yang.processor;

import static com.google.common.collect.Lists.newArrayList;

import java.util.List;

import org.eclipse.emf.common.notify.Adapter;
import org.eclipse.emf.common.notify.impl.AdapterImpl;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import com.google.gson.GsonBuilder;

import io.typefox.yang.processor.ProcessedDataTree.ElementData;
import io.typefox.yang.processor.ProcessedDataTree.ElementKind;
import io.typefox.yang.processor.ProcessedDataTree.HasStatements;
import io.typefox.yang.processor.ProcessedDataTree.ListData;
import io.typefox.yang.processor.ProcessedDataTree.ModuleData;
import io.typefox.yang.processor.ProcessorUtility.ModuleIdentifier;
import io.typefox.yang.yang.AbstractModule;
import io.typefox.yang.yang.Action;
import io.typefox.yang.yang.Augment;
import io.typefox.yang.yang.Case;
import io.typefox.yang.yang.Choice;
import io.typefox.yang.yang.Container;
import io.typefox.yang.yang.DataSchemaNode;
import io.typefox.yang.yang.Deviate;
import io.typefox.yang.yang.Deviation;
import io.typefox.yang.yang.Grouping;
import io.typefox.yang.yang.GroupingRef;
import io.typefox.yang.yang.IfFeature;
import io.typefox.yang.yang.Input;
import io.typefox.yang.yang.Leaf;
import io.typefox.yang.yang.LeafList;
import io.typefox.yang.yang.Notification;
import io.typefox.yang.yang.Output;
import io.typefox.yang.yang.Refine;
import io.typefox.yang.yang.Rpc;
import io.typefox.yang.yang.SchemaNode;
import io.typefox.yang.yang.Statement;
import io.typefox.yang.yang.Uses;

public class YangProcessor {

	public static void main(String[] args) {
		var processedData = new YangProcessor().process(newArrayList(), newArrayList(), newArrayList());
		new GsonBuilder().create().toJson(processedData, System.out);
	}

	/**
	 * 
	 * @param modules
	 * @param includedFeatures
	 * @param excludedFeatures
	 * @return ProcessedDataTree or <code>null</code> if modules is
	 *         <code>null</code> or empty.
	 */
	public ProcessedDataTree process(List<AbstractModule> modules, List<String> includedFeatures,
			List<String> excludedFeatures) {
		if (modules == null || modules.isEmpty()) {
			return null;
		}
		return processInternal(modules, includedFeatures == null ? newArrayList() : includedFeatures,
				excludedFeatures == null ? newArrayList() : excludedFeatures);
	}

	protected ProcessedDataTree processInternal(List<AbstractModule> modules, List<String> includedFeatures,
			List<String> excludedFeatures) {
		var evalCtx = new FeatureEvaluationContext(includedFeatures, excludedFeatures);
		ProcessedDataTree processedDataTree = new ProcessedDataTree();
		modules.forEach((module) -> module.eAllContents().forEachRemaining((ele) -> {
			if (ele instanceof Deviate) {
				/*
				 * var deviation = ((Deviation) ele); deviation.getSubstatements().forEach((sub)
				 * -> { });
				 */
				Deviate deviate = (Deviate) ele;
				switch (deviate.getArgument()) {
				case "add":
				case "replace":
					break;
				case "delete":
				case "not-supported":
					var deviation = ((Deviation) ele.eContainer());
					SchemaNode schemaNode = deviation.getReference().getSchemaNode();
					Object eGet = schemaNode.eContainer().eGet(schemaNode.eContainingFeature(), true);
					if (eGet instanceof EList) {
						((EList<?>) eGet).remove(schemaNode);
					}
					break;
				}
			} else if (ele instanceof Augment) {
				var augment = (Augment) ele;
				List<IfFeature> ifFeatures = ProcessorUtility.findIfFeatures(augment);
				boolean featuresMatch = ProcessorUtility.checkIfFeatures(ifFeatures, evalCtx);
				// disabled by feature
				if (!featuresMatch) {
					return;
				}
				var globalModuleId = ProcessorUtility.moduleIdentifier(module);

				augment.getSubstatements().stream().filter(sub -> !(sub instanceof IfFeature))
						.forEach((subStatement) -> {
							Statement copy = EcoreUtil.copy(subStatement);
							// add augment's feature conditions to copied augment children
							copy.getSubstatements().addAll(EcoreUtil.copyAll(ifFeatures));
							// memorize source module information as adapter
							copy.eAdapters().add(new ForeignModuleAdapter(globalModuleId));
							augment.getPath().getSchemaNode().getSubstatements().add(copy);
						});
			}
		}));

		modules.forEach((module) -> {
			var moduleData = new ModuleData(module);
			processedDataTree.addModule(moduleData);
			processChildren(module, moduleData);
		});
		return processedDataTree;
	}

	private void processChildren(Statement statement, HasStatements parent) {
		statement.getSubstatements().stream().forEach(ele -> {
			HasStatements child = null;
			if (ele instanceof Container) {
				child = new ElementData((Container) ele, ElementKind.Container);
			} else if (ele instanceof Leaf) {
				child = new ElementData((DataSchemaNode) ele, ElementKind.Leaf);
			} else if (ele instanceof LeafList) {
				child = new ElementData((DataSchemaNode) ele, ElementKind.LeafList);
			} else if (ele instanceof io.typefox.yang.yang.List) {
				child = new ListData((io.typefox.yang.yang.List) ele, ElementKind.List);
			} else if (ele instanceof Choice) {
				child = new ElementData((SchemaNode) ele, ElementKind.Choice);
			} else if (ele instanceof Case) {
				child = new ElementData((SchemaNode) ele, ElementKind.Case);
			} else if (ele instanceof Action) {
				child = new ElementData((SchemaNode) ele, ElementKind.Action);
			} else if (ele instanceof Grouping) {
				child = new ElementData((SchemaNode) ele, ElementKind.Grouping);
			} else if (ele instanceof Uses) {
				GroupingRef groupingRef = ((Uses) ele).getGrouping();
				ForeignModuleAdapter adapted = ForeignModuleAdapter.find(ele);
				Grouping grouping = groupingRef.getNode();
				if (adapted != null) {
					grouping.eAdapters().add(new ForeignModuleAdapter(adapted.moduleId));
				}
				processChildren(grouping, parent);
			} else if (ele instanceof Refine) {
				child = new ElementData((SchemaNode) ele, ElementKind.Refine);
			} else if (ele instanceof Input) {
				child = new ElementData((SchemaNode) ele, ElementKind.Input);
			} else if (ele instanceof Output) {
				child = new ElementData((SchemaNode) ele, ElementKind.Output);
			} else if (ele instanceof Notification) {
				child = new ElementData((SchemaNode) ele, ElementKind.Notification);
			} else if (ele instanceof Rpc) {
				var rpc = new ElementData((Rpc) ele, ElementKind.Rpc);
				((ModuleData) parent).addToRpcs(rpc);
				processChildren(ele, rpc);
			}
			if (child != null) {
				parent.addToChildren(child);
				processChildren(ele, child);
			}
		});
	}

	public static class ForeignModuleAdapter extends AdapterImpl {
		final ModuleIdentifier moduleId;

		public ForeignModuleAdapter(ModuleIdentifier moduleId) {
			this.moduleId = moduleId;
		}

		public static ForeignModuleAdapter find(EObject eObject) {
			for (Adapter adapter : eObject.eAdapters()) {
				if (adapter instanceof ForeignModuleAdapter) {
					return (ForeignModuleAdapter) adapter;
				}
			}
			if (eObject.eContainer() != null) {
				return find(eObject.eContainer());
			}
			return null;
		}
	}
}
