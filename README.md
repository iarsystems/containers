# IAR Cloud-ready Container Images

>[!IMPORTANT]
>Container images[^1] automatically generated from this repository are built from the corresponding IAR Releases on GitHub and are readily available via [GitHub Packages](https://github.com/orgs/iarsystems/packages). These are based on the latest IAR Platform and are tailored for evaluation in cloud-based environments and modern development workflows.

>[!WARNING]
>The information in this repository is subject to change without notice and does not constitute a commitment by IAR. While it serves as reference model for implementing Continuous Integration with IAR Tools, IAR assumes no responsibility for any errors, omissions, or specific implementations.

## GitHub Actions workflow
Pre-built container images are generated from annotated [workflows](.github/workflows) for the supported cloud-enabled products.

| Status | Origin | OS/Arch | Base image
| - | - | - | -
| [![arm-linux](https://github.com/iarsystems/containers/actions/workflows/arm-linux.yml/badge.svg)](https://github.com/iarsystems/containers/pkgs/container/arm)<br>[![arm-windows](https://github.com/iarsystems/containers/actions/workflows/arm-windows.yml/badge.svg)](https://github.com/iarsystems/containers/pkgs/container/arm) | [IAR Build Tools for Arm (CX)](https://github.com/iarsystems/arm) | linux/amd64<br>windows/amd64 | [`ghcr.io/iarsystems/arm`](https://github.com/iarsystems/containers/pkgs/container/arm)

All [container images](https://github.com/orgs/iarsystems/packages) produced from this repository are freshen on a schedule.

## Live examples
Below you will find live examples using these pre-built container images on projects and those can serve as inspiration for your own projects.
| Example | Description
| - | -
| [github-actions-ci-example](https://github.com/iarsystems/github-actions-ci-example) | Use a container image to produce automated builds.
| [iar-cmsis-dsp](https://github.com/iarsystems/iar-cmsis-dsp) | Automated builds for the Arm CMSIS-DSP libraries.


## Applying customizations
The simplest way to customize a container image is to create a new image using one of the provided images as base. This allows you to add tools, scripts, and resources as needed. If you are new to Docker, the [Docker manual](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) is a good place to start. We also provide a [__Cookbook__](https://github.com/iarsystems/containers/wiki) that includes tips, suggestions, and common recipes based on frequently encountered scenarios.

Alternatively, you can [create a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) or [import](https://docs.github.com/en/migrations/importing-source-code/using-github-importer/importing-a-repository-with-github-importer) this repository into your user account or organization account. From there, you can make modifications, commit changes, and have your custom images automatically built for you by GitHub Actions.


[^1]: The use of these images is subject to the [IAR Software License Agreement](https://github.com/iarsystems/containers/blob/master/LICENSE.md) and requires a valid subscription-based activation token for operation. If you are not yet a subscriber, please [contact us](https://iar.com/about/contact) for more information.
