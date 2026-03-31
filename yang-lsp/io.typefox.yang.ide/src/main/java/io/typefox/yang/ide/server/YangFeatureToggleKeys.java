package io.typefox.yang.ide.server;

import org.eclipse.xtext.preferences.PreferenceKey;

public class YangFeatureToggleKeys {
	public static final PreferenceKey COMPLETION = new PreferenceKey("completion", "on");
	public static final PreferenceKey HOVER = new PreferenceKey("hover", "on");
	public static final PreferenceKey DEFINITION = new PreferenceKey("definition", "on");
	public static final PreferenceKey REFERENCES = new PreferenceKey("references", "on");
	public static final PreferenceKey DOCUMENT_SYMBOLS = new PreferenceKey("document-symbols", "on");
	public static final PreferenceKey DOCUMENT_HIGHLIGHT = new PreferenceKey("document-highlight", "on");
	public static final PreferenceKey RENAME = new PreferenceKey("rename", "on");
}
