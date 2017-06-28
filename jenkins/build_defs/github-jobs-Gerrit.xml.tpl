<?xml version='1.0' encoding='UTF-8'?>
<!--
  Copyright 2015 The Bazel Authors. All rights reserved.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<matrix-project>
  <actions/>
  <description>Test that pull requests on the {{ variables.PROJECT_NAME }} project still build with Bazel at head and latest release.

This job for testing changes submitted to the Gerrit project: {{ variables.GERRIT_PROJECT }}.
</description>
  <keepDependencies>false</keepDependencies>
  <properties>
  {% if variables.github == "True" %}
    <com.coravy.hudson.plugins.github.GithubProjectProperty>
      <projectUrl>{{ variables.GITHUB_URL }}</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
  {% endif %}
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>REFSPEC</name>
          <description>Refs to pull</description>
          <defaultValue>+refs/heads/*:refs/remotes/origin/*</defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>BRANCH</name>
          <description>Branch to build</description>
          <defaultValue>master</defaultValue>
        </hudson.model.StringParameterDefinition>
        <hudson.model.StringParameterDefinition>
          <name>CHANGE_URL</name>
          <description>URL of the change being tested, for information only.</description>
          <defaultValue>no-change</defaultValue>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <scm class="hudson.plugins.git.GitSCM">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <refspec>${REFSPEC}</refspec>
        <url>https://bazel.googlesource.com/{{ variables.GERRIT_PROJECT }}</url>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
    <branches>
      <hudson.plugins.git.BranchSpec>
        <name>${BRANCH}</name>
      </hudson.plugins.git.BranchSpec>
    </branches>
    <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    <submoduleCfg class="list"/>
    <extensions>
      <hudson.plugins.git.extensions.impl.CleanBeforeCheckout/>
      <hudson.plugins.git.extensions.impl.AuthorInChangelog/>
      <hudson.plugins.git.extensions.impl.SubmoduleOption>
        <disableSubmodules>false</disableSubmodules>
        <recursiveSubmodules>true</recursiveSubmodules>
        <trackingSubmodules>false</trackingSubmodules>
      </hudson.plugins.git.extensions.impl.SubmoduleOption>
    </extensions>
  </scm>
  <quietPeriod>5</quietPeriod>
  <canRoam>true</canRoam>
  <disabled>{{ variables.disabled }}</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>true</blockBuildWhenUpstreamBuilding>
  <concurrentBuild>false</concurrentBuild>
  <axes>
    <hudson.matrix.LabelAxis>
      <name>PLATFORM_NAME</name>
      <values>{% for v in variables.PLATFORMS.split("\n") %}<string>{{ v }}</string>{% endfor %}</values>
    </hudson.matrix.LabelAxis>
    <hudson.matrix.TextAxis>
      <name>BAZEL_VERSION</name>
       <values>{% for v in variables.BAZEL_VERSIONS.split("\n") %}<string>{{ v }}</string>{% endfor %}</values>
    </hudson.matrix.TextAxis>
  </axes>
  <builders>
    <org.jenkinsci.plugins.conditionalbuildstep.ConditionalBuilder plugin="conditional-buildstep@1.3.3">
    <runner class="org.jenkins_ci.plugins.run_condition.BuildStepRunner$Fail" plugin="run-condition@1.0"/>
    <runCondition class="org.jenkins_ci.plugins.run_condition.core.ExpressionCondition" plugin="run-condition@1.0">
      <expression>^((?!windows).)*$</expression>
      <label>${PLATFORM_NAME}</label>
    </runCondition>
    <conditionalbuilders>
    <hudson.tasks.Shell>
      <command>{{ imports['//jenkins/build_defs:github-jobs.sh.tpl'] }}</command>
    </hudson.tasks.Shell>
    <hudson.tasks.Shell>
      <command>{{ imports['//jenkins/build_defs:github-jobs.test-logs.sh.tpl'] }}</command>
    </hudson.tasks.Shell>
    </conditionalbuilders>
    </org.jenkinsci.plugins.conditionalbuildstep.ConditionalBuilder>

    <org.jenkinsci.plugins.conditionalbuildstep.ConditionalBuilder plugin="conditional-buildstep@1.3.3">
      <runner class="org.jenkins_ci.plugins.run_condition.BuildStepRunner$Fail" plugin="run-condition@1.0"/>
      <runCondition class="org.jenkins_ci.plugins.run_condition.logic.And" plugin="run-condition@1.0">
        <conditions>
          <org.jenkins__ci.plugins.run__condition.logic.ConditionContainer>
            <condition class="org.jenkins_ci.plugins.run_condition.core.ExpressionCondition">
              <expression>windows.*</expression>
              <label>${PLATFORM_NAME}</label>
            </condition>
          </org.jenkins__ci.plugins.run__condition.logic.ConditionContainer>
        </conditions>
      </runCondition>
      <conditionalbuilders>
        <hudson.tasks.BatchFile>
          <command>{{ imports['//jenkins/build_defs:github-jobs.bat.tpl'] }}</command>
        </hudson.tasks.BatchFile>
        <hudson.tasks.BatchFile>
          <command>{{ imports['//jenkins/build_defs:github-jobs.test-logs.bat.tpl'] }}</command>
        </hudson.tasks.BatchFile>
      </conditionalbuilders>
    </org.jenkinsci.plugins.conditionalbuildstep.ConditionalBuilder>

    <org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder>
      <condition class="org.jenkins_ci.plugins.run_condition.core.FileExistsCondition">
        <file>.unstable</file>
        <baseDir class="org.jenkins_ci.plugins.run_condition.common.BaseDirectory$Workspace"/>
      </condition>
      <buildStep class="org.jenkins_ci.plugins.fail_the_build.FixResultBuilder">
        <defaultResultName>UNSTABLE</defaultResultName>
        <success></success>
        <unstable></unstable>
        <failure></failure>
        <aborted></aborted>
      </buildStep>
      <runner class="org.jenkins_ci.plugins.run_condition.BuildStepRunner$Unstable"/>
    </org.jenkinsci.plugins.conditionalbuildstep.singlestep.SingleConditionalBuilder>
  </builders>
  <publishers>
    <hudson.tasks.junit.JUnitResultArchiver>
      <testResults>bazel-testlogs/**/test.xml, bazel-testlogs/**/dummy.xml</testResults>
      <keepLongStdio>false</keepLongStdio>
      <healthScaleFactor>1.0</healthScaleFactor>
      <allowEmptyResults>true</allowEmptyResults>
    </hudson.tasks.junit.JUnitResultArchiver>
    <com.cloudbees.jenkins.GitHubCommitNotifier>
      <resultOnFailure>FAILURE</resultOnFailure>
    </com.cloudbees.jenkins.GitHubCommitNotifier>
  </publishers>
  <buildWrappers>
    <hudson.plugins.build__timeout.BuildTimeoutWrapper>
      <strategy class="hudson.plugins.build_timeout.impl.AbsoluteTimeOutStrategy">
        <timeoutMinutes>240</timeoutMinutes>
      </strategy>
      <operationList>
        <hudson.plugins.build__timeout.operations.FailOperation/>
        <hudson.plugins.build__timeout.operations.WriteDescriptionOperation>
          <description>Timed out</description>
        </hudson.plugins.build__timeout.operations.WriteDescriptionOperation>
      </operationList>
    </hudson.plugins.build__timeout.BuildTimeoutWrapper>
  </buildWrappers>
  <executionStrategy class="hudson.matrix.DefaultMatrixExecutionStrategyImpl">
    <runSequentially>false</runSequentially>
  </executionStrategy>
</matrix-project>
