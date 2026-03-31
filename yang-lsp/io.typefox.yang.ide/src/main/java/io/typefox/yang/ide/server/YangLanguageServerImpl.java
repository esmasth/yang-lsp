/*
 * Copyright (C) 2017-2020 TypeFox and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at http://www.apache.org/licenses/LICENSE-2.0
 */
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
