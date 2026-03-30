package io.typefox.yang.tests.validation

import io.typefox.yang.settings.PreferenceValuesProvider
import io.typefox.yang.tests.AbstractYangTest
import io.typefox.yang.validation.ResourceValidator
import org.junit.After
import org.junit.Assert
import org.junit.Test

class FeatureToggleTest extends AbstractYangTest {

	@After def void cleanup() {
		PreferenceValuesProvider.constantSettings.remove(ResourceValidator.VALIDATION_ENABLED.id)
	}

	@Test def void testValidationOnByDefault() {
		val m = load('''
			module foo {
				namespace urn:foo;
				prefix foo;
				revision 2999-99-99;
			}
		''')
		val issues = validator.validate(m.root)
		Assert.assertFalse('Expected validation issues', issues.isEmpty)
	}

	@Test def void testValidationDisabled() {
		PreferenceValuesProvider.constantSettings.put('validation', 'off')
		val m = load('''
			module foo {
				namespace urn:foo;
				prefix foo;
				revision 2999-99-99;
			}
		''')
		val issues = validator.validate(m.root)
		Assert.assertTrue('Expected no issues when validation is off', issues.isEmpty)
	}
}
