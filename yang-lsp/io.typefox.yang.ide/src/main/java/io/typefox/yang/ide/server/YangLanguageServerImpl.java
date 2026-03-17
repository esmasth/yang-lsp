package io.typefox.yang.ide.server;

import org.eclipse.lsp4j.Diagnostic;
import org.eclipse.xtext.ide.server.LanguageServerImpl;
import org.eclipse.xtext.validation.Issue;

public class YangLanguageServerImpl extends LanguageServerImpl {

	@Override
	protected Diagnostic toDiagnostic(Issue issue) {
		Diagnostic diagnostic = super.toDiagnostic(issue);
		diagnostic.setSource("yang-lsp");
		return diagnostic;
	}
}
