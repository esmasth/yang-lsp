/*
 * Copyright (C) 2017-2020 TypeFox and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at http://www.apache.org/licenses/LICENSE-2.0
 */
package io.typefox.yang.tests.validation

import io.typefox.yang.ide.server.YangLanguageServerImpl
import io.typefox.yang.tests.AbstractYangLSPTest
import org.eclipse.xtext.ide.server.LanguageServerImpl
import org.eclipse.xtext.util.Modules2
import org.junit.Assert
import org.junit.Test

class DiagnosticSourceTest extends AbstractYangLSPTest {

	override protected getServerModule() {
		Modules2.mixin(super.getServerModule()) [
			bind(LanguageServerImpl).to(YangLanguageServerImpl)
		]
	}

	@Test def void testDiagnosticHasSource() {
		initialize
		val uri = 'inmemory:/foo/foo.yang'
		open(uri, '''
			module foo {
				import nonexistent {
					prefix n;
				}
			}
		''')
		val issues = diagnostics.get(uri)
		Assert.assertFalse("Expected at least one diagnostic", issues.nullOrEmpty)
		for (issue : issues) {
			Assert.assertEquals("yang-lsp", issue.source)
		}
	}
}
