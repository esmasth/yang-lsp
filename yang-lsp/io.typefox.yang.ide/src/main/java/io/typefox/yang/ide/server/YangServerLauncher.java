/*
 * Copyright (C) 2017-2020 TypeFox and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at http://www.apache.org/licenses/LICENSE-2.0
 */
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
