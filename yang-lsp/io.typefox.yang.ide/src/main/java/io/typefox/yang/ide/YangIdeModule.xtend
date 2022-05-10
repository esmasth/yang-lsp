/*
 * generated by Xtext 2.13.0-SNAPSHOT
 */
package io.typefox.yang.ide

import io.typefox.yang.ide.codeAction.CodeActionService
import io.typefox.yang.ide.codelens.CodeLensService
import io.typefox.yang.ide.completion.YangContentAssistService
import io.typefox.yang.ide.completion.YangContentProposalAcceptor
import io.typefox.yang.ide.completion.YangContentProposalCreator
import io.typefox.yang.ide.completion.YangContentProposalProvider
import io.typefox.yang.ide.completion.YangCrossrefProposalProvider
import io.typefox.yang.ide.contentassist.antlr.lexer.InternalYangLexer
import io.typefox.yang.ide.contentassist.antlr.lexer.jflex.JFlexBasedInternalYangLexer
import io.typefox.yang.ide.editor.syntaxcoloring.YangSemanticHighlightingCalculator
import io.typefox.yang.ide.extensions.CommandService
import io.typefox.yang.ide.formatting.YangFormattingService
import io.typefox.yang.ide.rename.YangRenameStrategy
import io.typefox.yang.ide.symbols.YangDocumentSymbolKindProvider
import io.typefox.yang.ide.symbols.YangDocumentSymbolNameProvider
import io.typefox.yang.ide.symbols.YangDocumentSymbolService
import io.typefox.yang.ide.symbols.YangHierarchicalDocumentSymbolService
import java.util.List
import org.eclipse.lsp4j.CodeLens
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalAcceptor
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalCreator
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalProvider
import org.eclipse.xtext.ide.editor.contentassist.IdeCrossrefProposalProvider
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.ide.refactoring.IRenameStrategy2
import org.eclipse.xtext.ide.server.Document
import org.eclipse.xtext.ide.server.codeActions.ICodeActionService2
import org.eclipse.xtext.ide.server.codelens.ICodeLensResolver
import org.eclipse.xtext.ide.server.codelens.ICodeLensService
import org.eclipse.xtext.ide.server.commands.IExecutableCommandService
import org.eclipse.xtext.ide.server.contentassist.ContentAssistService
import org.eclipse.xtext.ide.server.formatting.FormattingService
import org.eclipse.xtext.ide.server.symbol.DocumentSymbolMapper.DocumentSymbolKindProvider
import org.eclipse.xtext.ide.server.symbol.DocumentSymbolMapper.DocumentSymbolNameProvider
import org.eclipse.xtext.ide.server.symbol.DocumentSymbolService
import org.eclipse.xtext.ide.server.symbol.HierarchicalDocumentSymbolService
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.util.CancelIndicator

/**
 * Use this class to register ide components.
 */
class YangIdeModule extends AbstractYangIdeModule {

	def Class<? extends IdeContentProposalProvider> bindIdeContentProposalProvider() {
		return YangContentProposalProvider
	}

	def Class<? extends InternalYangLexer> bindInternalYangLexer() {
		return JFlexBasedInternalYangLexer;
	}

	def Class<? extends DocumentSymbolService> bindDocumentSymbolService() {
		return YangDocumentSymbolService;
	}

	def Class<? extends ICodeLensService> bindICodeLensService() {
		return CodeLensService;
	}

	def Class<? extends ICodeLensResolver> bindICodeLensResolver() {
		return NoOpCodeLensResolver;
	}

	def Class<? extends ContentAssistService> bindContentAssistService() {
		return YangContentAssistService;
	}

	def Class<? extends IdeContentProposalAcceptor> bindIdeContentProposalAcceptor() {
		return YangContentProposalAcceptor;
	}

	def Class<? extends IdeCrossrefProposalProvider> bindIdeCrossrefProposalProvider() {
		return YangCrossrefProposalProvider;
	}

	def Class<? extends IdeContentProposalCreator> bindIdeContentProposalCreator() {
		return YangContentProposalCreator;
	}

	def Class<? extends ICodeActionService2> bindICodeActionService2() {
		return CodeActionService;
	}

	def Class<? extends IExecutableCommandService> bindIExecutableCommandService() {
		return CommandService
	}

	override Class<? extends IRenameStrategy2> bindIRenameStrategy2() {
		return YangRenameStrategy
	}

	static class NoOpCodeLensResolver implements ICodeLensResolver {

		override resolveCodeLens(Document document, XtextResource resource, CodeLens codeLens,
			CancelIndicator indicator) {
			// HACKY fix for https://github.com/TypeFox/monaco-languageclient/pull/6
			if (codeLens?.command?.arguments?.head instanceof List<?>) {
				codeLens.command.arguments = codeLens.command.arguments.head as List<Object>
			}
			return codeLens
		}

	}

	def Class<? extends FormattingService> bindFormattingService() {
		YangFormattingService
	}

	def Class<? extends ISemanticHighlightingCalculator> bindISemanticHighlightingCalculator() {
		return YangSemanticHighlightingCalculator;
	}
/*
 
	def Class<? extends ISemanticHighlightingStyleToTokenMapper> bindISemanticHighlightingStyleToTokenMapper() {
		return YangSemanticHighlightingCalculator;
	}
 */

	def Class<? extends HierarchicalDocumentSymbolService> bindHierarchicalDocumentSymbolService() {
		return YangHierarchicalDocumentSymbolService;
	}

	def Class<? extends DocumentSymbolKindProvider> bindDocumentSymbolKindProvider() {
		return YangDocumentSymbolKindProvider;
	}

	def Class<? extends DocumentSymbolNameProvider> bindDocumentSymbolNameProvider() {
		return YangDocumentSymbolNameProvider;
	}

}
