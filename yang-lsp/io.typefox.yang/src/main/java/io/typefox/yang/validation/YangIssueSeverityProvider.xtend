package io.typefox.yang.validation

import com.google.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.preferences.PreferenceKey
import org.eclipse.xtext.util.internal.Log
import org.eclipse.xtext.validation.ConfigurableIssueCodesProvider
import org.eclipse.xtext.validation.IssueSeverities
import org.eclipse.xtext.validation.IssueSeveritiesProvider
import org.eclipse.xtext.validation.SeverityConverter

@Log class YangIssueSeverityProvider extends IssueSeveritiesProvider {

	@Inject ConfigurableIssueCodesProvider issueCodesProvider
	@Inject SeverityConverter severityConverter

	override getIssueSeverities(Resource context) {
		val preferenceValues = getValuesProvider().getPreferenceValues(context);
		val configurableIssueCodes = issueCodesProvider.getConfigurableIssueCodes()
		return new IssueSeverities(preferenceValues, issueCodesProvider.getConfigurableIssueCodes(),
			severityConverter) {
			override Severity getSeverity(String code) {
				val key = configurableIssueCodes.get(code)
				val defaultSeverity = key?.defaultValue
				val prefKey = new PreferenceKey('diagnostic.'+code, defaultSeverity ?: '')
				val value = preferenceValues.getPreference(prefKey)
				if (value.nullOrEmpty) return null
				try {
					return severityConverter.stringToSeverity(value)
				} catch (IllegalArgumentException e) {
					LOG.error(e.getMessage(), e)
					return Severity.ERROR
				}
			}
		};
	}

}
