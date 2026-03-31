package io.typefox.yang.utils

import com.google.inject.Inject
import com.google.inject.Injector
import io.typefox.yang.settings.PreferenceValuesProvider
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.preferences.IPreferenceValues
import org.eclipse.xtext.preferences.MapBasedPreferenceValues
import org.eclipse.xtext.preferences.PreferenceKey
import org.eclipse.xtext.util.internal.Log

@Log class ExtensionProvider {
	
	@Inject ExtensionClassPathProvider classPathProvider
	@Inject PreferenceValuesProvider preferenceProvider
	@Inject Injector injector
	
	Map<String, Entry> cache = newHashMap()
	
	@Data static class Entry {
		String configuredValue
		List<?> cachedExtensionObjects
	}
	
	def <T> List<T> getExtensions(PreferenceKey key, Resource res, Class<T> clazz) {
		return doGetExtensions(key, res, clazz, false)
	}
	
	def <T> List<T> getMergedExtensions(PreferenceKey key, Resource res, Class<T> clazz) {
		return doGetExtensions(key, res, clazz, true)
	}
	
	private def <T> List<T> doGetExtensions(PreferenceKey key, Resource res, Class<T> clazz, boolean merge) {
		val preferences = preferenceProvider.getPreferenceValues(res)
		val value = if (merge) collectMergedValue(key, preferences) else preferences.getPreference(key)
		val previous = cache.get(key)
		if (previous !== null && previous.configuredValue == value) {
			return previous.cachedExtensionObjects as List<T>
		}
		val result = newArrayList()
		val classLoader = classPathProvider.getExtensionLoader(res)
		for (className : value.split(':')) {
			if (!className.isNullOrEmpty) {
				try {
					val extensionClass = classLoader.loadClass(className)
					val extensionInstance = extensionClass.newInstance
					injector.injectMembers(extensionInstance)
					result.add(extensionInstance)				
				} catch (Exception e) {
					LOG.error("Could not load extension class '"+className+"'", e)
				}
			}
		}
		cache.put(key.id, new Entry(value, result))
		return result as List<T>
	}
	
	private def String collectMergedValue(PreferenceKey key, IPreferenceValues preferences) {
		val classNames = new LinkedHashSet<String>()
		var current = preferences
		while (current !== null) {
			if (current instanceof MapBasedPreferenceValues) {
				val localValue = current.values.get(key.id)
				if (!localValue.isNullOrEmpty) {
					for (name : localValue.split(':')) {
						if (!name.isNullOrEmpty) classNames.add(name)
					}
				}
				current = current.delegate
			} else {
				current = null
			}
		}
		return String.join(':', classNames)
	}
}