/*
 * Copyright 2012-2025 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.springframework.samples.petclinic;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;
import org.springframework.data.repository.Repository;
import org.springframework.stereotype.Controller;
import org.springframework.stereotype.Service;

/**
 * Architecture rules documenting the existing structure of the application.
 */
@AnalyzeClasses(packages = "org.springframework.samples.petclinic",
		importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTests {

	/**
	 * There is no service layer: controllers talk directly to repositories.
	 */
	@ArchTest
	static final ArchRule noServiceLayer = noClasses().should()
		.beAnnotatedWith(Service.class)
		.orShould()
		.haveSimpleNameEndingWith("Service");

	@ArchTest
	static final ArchRule repositoriesDoNotDependOnControllers = noClasses().that()
		.areAssignableTo(Repository.class)
		.should()
		.dependOnClassesThat()
		.areAnnotatedWith(Controller.class);

	@ArchTest
	static final ArchRule packagesAreFreeOfCycles = slices().matching("org.springframework.samples.petclinic.(*)..")
		.should()
		.beFreeOfCycles();

	@ArchTest
	static final ArchRule modelDoesNotDependOnFeaturePackages = noClasses().that()
		.resideInAPackage("..petclinic.model..")
		.should()
		.dependOnClassesThat()
		.resideInAnyPackage("..petclinic.owner..", "..petclinic.vet..", "..petclinic.system..");

}
