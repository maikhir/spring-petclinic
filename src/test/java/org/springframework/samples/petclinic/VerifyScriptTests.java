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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Guards the single verification entry point used by the agent harness.
 */
class VerifyScriptTests {

	private static final Path SCRIPT = Path.of("scripts", "verify.sh");

	@Test
	void verifyScriptExistsAndIsExecutable() {
		assertThat(SCRIPT).isRegularFile();
		assertThat(Files.isExecutable(SCRIPT)).isTrue();
	}

	@Test
	void verifyScriptRunsTheFullBuild() throws IOException {
		assertThat(Files.readString(SCRIPT)).contains("./mvnw -B verify");
	}

}
