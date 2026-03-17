package io.typefox.yang.ide.server;

import org.eclipse.xtext.ide.server.LanguageServerImpl;
import org.eclipse.xtext.ide.server.ProjectManager;
import org.eclipse.xtext.ide.server.ServerLauncher;
import org.eclipse.xtext.ide.server.ServerModule;

public class YangServerLauncher {

	public static void main(String[] args) {
		ServerLauncher.launch(YangServerLauncher.class.getName(), args, new ServerModule(), binder -> {
			binder.bind(LanguageServerImpl.class).to(YangLanguageServerImpl.class);
			binder.bind(ProjectManager.class).to(YangProjectManager.class);
		});
	}
}
