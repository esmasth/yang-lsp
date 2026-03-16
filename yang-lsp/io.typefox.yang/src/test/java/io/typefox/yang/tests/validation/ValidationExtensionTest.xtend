package io.typefox.yang.tests.validation

import io.typefox.yang.tests.AbstractYangTest
import java.io.File
import java.io.FileWriter
import org.eclipse.xtext.diagnostics.Severity
import org.eclipse.xtext.workspace.FileProjectConfig
import org.eclipse.xtext.workspace.ProjectConfigAdapter
import org.junit.Assert
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class ValidationExtensionTest extends AbstractYangTest {
	
	static val BAD_NAME = "bad_name"
	
	@Rule public val tempFolder = new TemporaryFolder
	
	@Test def void testExtensionNotRegistered() {
		val m  = load('''
			module foo {
				
			}
		''')
		assertNoErrors(m.root, BAD_NAME)
	}
	
	@Test def void testExtensionRegistered() {
		val root = new File("./src/test/resources/project").canonicalFile
		ProjectConfigAdapter.install(resourceSet, new FileProjectConfig(root))
		
		val m  = load('''
			module foo {
				
			}
		''')
		val validate = this.validator.validate(m.root.eResource)
		val issue = validate.findFirst[code == BAD_NAME]
		Assert.assertEquals(Severity.WARNING, issue.severity)
	}
	
	@Test def void testExtensionAbsoluteClasspath() {
		val jarPath = new File("./src/test/resources/project/extension.jar").canonicalPath
		val projectDir = tempFolder.newFolder("yang-test")
		val settings = new File(projectDir, "yang.settings")
		val writer = new FileWriter(settings)
		writer.write('''
			{
				"diagnostic" : {
					"bad_name" : "warning"
				},
				"extension" : {
					"classpath" : "«jarPath»",
					"validators" : "io.typefox.yang.tests.validation.MyValidatorExtension"
				}
			}
		'''.toString)
		writer.close
		
		ProjectConfigAdapter.install(resourceSet, new FileProjectConfig(projectDir))
		
		val m  = load('''
			module foo {
				
			}
		''')
		val validate = this.validator.validate(m.root.eResource)
		val issue = validate.findFirst[code == BAD_NAME]
		Assert.assertNotNull("Expected issue with code " + BAD_NAME, issue)
		Assert.assertEquals(Severity.WARNING, issue.severity)
	}
}