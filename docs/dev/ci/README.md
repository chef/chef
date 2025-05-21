# Using Buildkite to build Chef Omnibus Packages

- [Buildkite Dynamic Pipelines](#buildkite-dynamic-pipelines)
  - [.buildkite/verify.pipeline.sh](#buildkiteverifypipelinesh)
  - [.buildkite/verify.adhoc.pipeline.sh](#buildkiteverifyadhocpipelinesh)
  - [.buildkite/build-test-omnibus.sh](#buildkitebuild-test-omnibussh)
- [Artifact Publish Locations](#artifact-publish-locations)
- [Omnibus Build & Test Platforms](#omnibus-build--test-platforms)
  - [Docker Container Platforms](#docker-container-platforms)
  - [Esoteric Platforms](#esoteric-platforms)
- [Triggering pull-request builds of chef](#triggering-pull-request-builds-of-chef)
- [Triggering release builds of chef](#triggering-release-builds-of-chef)
- [Triggering adhoc builds of chef](#triggering-adhoc-builds-of-chef)
  - [Building and/or testing subset of platforms using OMNIBUS_FILTER](#building-andor-testing-subset-of-platforms-using-omnibus_filter)
- [Viewing the Pipeline YAML](#viewing-the-pipeline-yaml)
- [Walk-through of what happens in the verify pipeline](#walk-through-of-what-happens-in-the-verify-pipeline)
- [FAQs](#faqs)


## Buildkite Dynamic Pipelines

Buildkite has a feature called [dynamic pipelines]() that allows for generate the pipeline.yaml file using any language. We implemented the new chef pipelines using bash instead of expeditor so that the pipeline configuration would be part of the chef/chef repo and not a proprietary tool which the community does not have access to change.

### .buildkite/verify.pipeline.sh

The new verify pipeline runs on pull-requests, merges to main (release builds). It runs all of the previous unit, functional and integration tests but inside of an omnibus-toolchain docker container. At run time, the `.buildkite-platform.json` file is used to determine the version of omnibus-toolchain and chef-foundation to install. This will help keep the dependencies used to build chef in source control for reproducing builds later on.

This pipeline also builds and tests omnibus packages in a subset of the supported platforms. This is to ensure a pull-requests does not break an omnibus build before merging. All of these platforms are now running in omnibus-toolchain docker containers as well so developers can debug locally easier and the build & test environments are never tainted by previous executions. Omnibus packages built by a pull-request are available from the buildkite artifact store.

The release pipeline is just the verify pipeline again but with additional steps to upload the artifacts to artifactory and make them available in the "current" channel of omnitruck.

### .buildkite/verify.adhoc.pipeline.sh

The new adhoc pipeline can be used by a chef organization member to test an omnibus build & test of "esoteric" platforms or a specific platform before merging a pull-request.

The adhoc pipeline is just the verify pipeline again but only the omnibus build & test steps.

### .buildkite/build-test-omnibus.sh

The build-test-omnibus script is a shared script executed by both the verify pipeline and adhoc pipeline. It is meant to keep the pipelines DRY.

## Artifact Publish Locations

Chef pipelines upload and make available the artifacts they create to the following locations.

Location | `verify` | `validate/release` | `validate/adhoc`
--- | --- | --- | ---
[Buildkite Artifacts](https://buildkite.com/docs/pipelines/artifacts) | Yes | Yes | Yes |
Artifactory | No | Yes | No

## Omnibus Build & Test Platforms

Omnibus packages for chef-infra-client are built & tested on either a docker container or a virtual machine.

### Docker Container Platforms

Name | Compute | Pipeline |
--- | --- | --- |
amazon-2 | :whale: | verify, validate/adhoc, validate/release |
centos-6 | :whale: | verify, validate/adhoc, validate/release |
centos-7 | :whale: | verify, validate/adhoc, validate/release |
centos-8 | :whale: | verify, validate/adhoc, validate/release |
rhel-9 | :whale: | verify, validate/adhoc, validate/release |
debian-9 | :whale: | verify, validate/adhoc, validate/release |
debian-10 | :whale: | verify, validate/adhoc, validate/release |
debian-11 | :whale: | verify, validate/adhoc, validate/release |
ubuntu-1604 | :whale: | verify, validate/adhoc, validate/release |
ubuntu-1804 | :whale: | verify, validate/adhoc, validate/release |
ubuntu-2004 | :whale: | verify, validate/adhoc, validate/release |
ubuntu-2204 | :whale: | verify, validate/adhoc, validate/release |
sles-15 | :whale: | verify, validate/adhoc, validate/release |
windows-2019 | :whale: | verify, validate/adhoc, validate/release |
windows-2012 | :computer: / :whale: | verify, validate/adhoc, validate/release |
windows-2012r2 | :computer: / :whale: | verify, validate/adhoc, validate/release |
windows-2016 | :computer: / :whale: | verify, validate/adhoc, validate/release |
windows-2022 | :computer: / :whale: | verify, validate/adhoc, validate/release |
windows-10 | :computer: / :whale: | verify, validate/adhoc, validate/release |
windows-11 | :computer: / :whale: | verify, validate/adhoc, validate/release |

**Containers exist for windows platforms but integration tests cannot pass inside a docker container.**

### Esoteric Platforms

Name | Compute | Pipeline |
--- | --- | --- |
aix-7.1-powerpc | :computer: | validate/adhoc, validate/release |
aix-7.2-powerpc | :computer: | validate/adhoc, validate/release |
aix-7.3-powerpc | :computer: | validate/adhoc, validate/release |
el-7-ppc64 | :computer: | validate/adhoc, validate/release |
el-7-ppc64le | :computer: | validate/adhoc, validate/release |
el-7-s390x | :computer: | validate/adhoc, validate/release |
el-8-s390x | :computer: | validate/adhoc, validate/release |
freebsd-12-amd64 | :computer: | validate/adhoc, validate/release |
freebsd-13-amd64 | :computer: | validate/adhoc, validate/release |
mac_os_x-10.15-x86_64 | :computer: | validate/adhoc, validate/release |
mac_os_x-11-x86_64 | :computer: | validate/adhoc, validate/release |
mac_os_x-12-x86_64 | :computer: | validate/adhoc, validate/release |
mac_os_x-11-arm64 | :computer: | validate/adhoc, validate/release |
mac_os_x-12-arm64 | :computer: | validate/adhoc, validate/release |
solaris2-5.11-i386 | :computer: | validate/adhoc, validate/release |
solaris2-5.11-sparc | :computer: | validate/adhoc, validate/release |
sles-12-s390x | :computer: | validate/adhoc, validate/release |
sles-15-s390x | :computer: | validate/adhoc, validate/release |

**Esoteric platforms have limited availability so they are not tested on pull-requests unless using the adhoc pipeline**

## Triggering pull-request builds of chef

There are three ways to trigger chef's `verify` pipeline.

1. **Via opening a pull-request or pushing a commit to a pull-request branch.** 
2. **Via the Buildkite UI.** Triggering a verify build [via the Buildkite UI](https://buildkite.com/docs/tutorials/getting-started#create-your-first-build) is useful when there may have been a transient failure or a failure due to a problem with the buildkite platform.
3. **Via the Buildkite CLI.** If you have the [Buildkite CLI](https://expeditor.chef.io/docs/getting-started/integrations/#buildkite-cli) configured, you can trigger a verify pipeline manually using the `bk build create` command.

```bash
bk build create --pipeline=chef-oss/chef-main-verify
```

## Triggering release builds of chef

There are three ways to trigger chef's `validate/release` pipeline.

1. **Via the trigger_pipeline:validate/release action** The pipeline is automatically executed on a commit to the main branch.
2. **Via the Buildkite UI.** Triggering a release build [via the Buildkite UI](https://buildkite.com/docs/tutorials/getting-started#create-your-first-build) is useful when you need to trigger a fresh build out of band of a code change to your project.
3. **Via the Buildkite CLI.** If you have the [Buildkite CLI](https://expeditor.chef.io/docs/getting-started/integrations/#buildkite-cli) configured, you can trigger a release pipeline manually using the `bk build create` command.

```bash
bk build create --pipeline=chef/chef-main-validate-release
```

## Triggering adhoc builds of chef

There are two ways we recommend to trigger you `validate/adhoc` pipeline.

1. **Via the Buildkite UI.** Triggering an adhoc build [via the Buildkite UI](https://buildkite.com/docs/tutorials/getting-started#create-your-first-build) is useful when you need test that an omnibus build & test of your branch will succeed on esoteric platforms.
2. **Via the Buildkite CLI.** If you have the [Buildkite CLI](https://expeditor.chef.io/docs/getting-started/integrations/#buildkite-cli) configured, you can trigger a release pipeline manually using the `bk build create` command.

```bash
bk build create --pipeline=chef/chef-main-validate-adhoc
```

### Building and/or testing subset of platforms using OMNIBUS_FILTER

The `OMNIBUS_FILTER` feature of the expeditor-generated omnibus pipelines is supported by the dynamic buildkite pipeline. See the [OMNIBUS_FILTER](https://expeditor.chef.io/docs/pipelines/omnibus/#building-andor-testing-subset-of-platforms-using-omnibus_filter) section of the expeditor docs for a description of how that works.

## Viewing the Pipeline YAML

There are two ways of viewing the pipeline YAML that is generated by `.buildkite/verify.pipeline.sh`.

1. **Via the Buildkite UI.** Once a build has been triggered, navigate to the job and expand the `upload` step. There is a tab labeled `timeline` that will show the YAML generated by the dynamic pipeline.

2. **Via executing the script.** Generate the pipeline YAML by executing the script, passing the required environment variables.

```bash
export OMNIBUS_TOOLCHAIN_VERSION=3.0.0
export CHEF_FOUNDATION_VERSION=3.0.3
export BUILDKITE_ORGANIZATION_SLUG="chef" # or chef-oss
export BUILDKITE_PIPELINE_SLUG="chef-main-validate-release"
./.buildkite/verify.pipeline.sh
```

## Walk-through of what happens in the verify pipeline

Let's break down the steps of the chef verify pipeline build and walk through all the processes.

1. **.buildkite/pre-command.** The pre-command buildkite hook parses the `.buildkite-platform.json` file for the versions of tools it needs to install at runtime and exports them as environment variables.
1. **Upload step** The upload step executes a dynamic pipeline script which write yaml to STDOUT and pipes the output to the buildkite agent. Environment variable are used to determine the YAML generated by the script.
1. **Unit/Functional/Integration Tests** Run all unit, functional, and integration tests on the containerized platforms using chef-foundation for runtime dependencies.
1. **Dependant Gem Tests** Run all dependant gem tests using chef-foundation for runtime dependencies.
1. **Omnibus Build & Test all the non-esoteric platforms** The non-esoteric platforms are the most likely to succeed so they act as a "canary" type omnibus build because esoteric platforms wait for them to succeed before running.
1. **Test all of the non-esoteric omnibus packages.** The non-esoteric omnibus packages are tested using the omnibus/omnibus-test.sh or omnibus/omnibus-test.ps1 scripts.
1. **Build habitat packages** Build and test the official chef-infra-client habitat packages.
1. **Omnibus Build & Test all the esoteric platforms (validate/release only).** The container platforms are the most likely to succeed so they act as a "canary" type omnibus build because esoteric platforms wait for them to succeed before running.
1. **Create the Build Record (validate/release only).** Upon the completion of all the builds, a build record representing all the artifacts is created inside Artifactory.
1. **Test all of the esoteric omnibus packages (validate/release only).** The esoteric omnibus packages are tested using the omnibus/omnibus-test.sh or omnibus/omnibus-test.ps1 scripts.
1. **Promote to the current channel (validate/release only).** Once all of the tests scripts have passed successfully, our builds are promoted to the current channel, where they can be consumed by early adopters and other beta/QA testers.

## FAQs

<details>
<summary>1. Why are some platforms built and tested using docker containers?</summary>
<br>
We chose docker containers because they provide a clean-room environment for each omnibus build. It also makes it much easier to add support for platforms when they can be containerized. We realize this adds complexity to the pipeline because there are 2 different types of compute now but the trade-offs are (hopefully) worth it.
<br>
<br>
</details>
<br>

<details>
<summary>2. Why did we introduce chef-foundation?</summary>
<br>
The introduction of chef-foundation is to help prevent the need to compile runtime dependencies for chef with each release. It is also meant to help speed up builds and make adding newer versions of runtime dependencies like ruby easier.
<br>
<br>
</details>
<br>

<details>
<summary>3. Why are the previous adhoc and release pipelines still there?</summary>
<br>
They are kept around for historical purposes. Once this pipeline is backported to chef 16 and 17 and deemed stable, they can be removed. Removing them from `.expeditor/config.yml` will delete the pipelines in buildkite.
<br>
<br>
</details>
<br>
