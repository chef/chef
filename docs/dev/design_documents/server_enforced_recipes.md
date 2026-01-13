# Server Enforced Recipe

## Description

Chef Server will provide an endpoint that MAY serve a Chef recipe file. Chef
Client will attempt to fetch the recipe during run context setup. If
no user action is taken to configure the feature, the endpoint returns 404
and Client behavior will be unaffected. When the feature is enabled, the
endpoint returns the configured recipe file. Chef Client will evaluate and
converge the recipe.

## Rationale

The motivation for this feature is to allow the operator of the Chef Server to
enforce limited desired client-side configuration using Chef. Intended use
cases include:

* Allow cloud-based vendors to install an agent necessary for correct operation
  of the service
* Allow Chef Customer Development Partners to efficiently install experimental
  client-side software during feature development
* Allow organizations that operate as internal service providers to enforce
  standard configurations

This feature is targeted at expert level practitioners who are delivering
isolated configuration changes to the target systems, such as self-contained
agent software. Users who wish to deliver more comprehensive configuration
changes should not use this mechanism to deliver those changes directly, but
could configure an additional Chef Client identity (i.e., node name, client
key, organization/server url) to deliver those changes via this feature.

As this feature is intended to be used in a manner that is as unobtrusive as
possible, and in cases where the Chef Server is administrated by a vendor on
behalf of the user, existing approaches to enforcing client-side configuration
are not sufficient.

The enforced policy is limited to a single recipe instead of a full cookbook or
secondary run list for several reasons:

* Cookbooks are Chef Server objects that are organization-scoped and subject to
  authorization restrictions. Allowing some cookbooks to be global requires
  additional complexity, which is not needed for the intended uses.
* Cookbooks have versions and dependencies, which have to be solved. There are
  several ways this could be addressed, but all options introduce unneeded
  complexity into the solution.
* Attributes are not usable for the intended use case, since the author(s) of
  the enforced recipe code may have no control over the node data, roles, JSON
  files, or policyfiles used by the nodes being managed.
* Other cookbook features, such as libraries and the various flavors of
  resources and providers, set ruby constants, which could interfere with the
  correct operation of the end user's cookbooks.
* Templates and cookbook files would be useful, but expert practitioners will
  be able to be effective without them.

## Motivation

    As a Chef Server Service Provider,
    I want to enforce a recipe to run on client systems,
    so that I can ensure client systems are correctly configured.

## Specification

### Enforced Recipe Endpoint

Chef Server shall expose an organization-scoped endpoint for the enforced
recipe. If the feature has not been configured by the Chef Server
administrator, the endpoint shall return a 404 response. If the feature is
enabled by the Chef Server administrator, the endpoint shall return a 200
response with the recipe content as the response body.

The endpoint shall authenticate the request via Chef Server's usual
authentication mechanism.

No authorization mechanism is provided. Any user or client with API access to
any organization on the Chef Server will have read-only access to the enforced
recipe.

The URL path of the endpoint relative to the organization base path will be
determined at a future time.

### Chef Server Configuration

The interface for configuring the feature is to be determined.

Though the initial implementation will likely only support a standalone Chef
Server deployment, the configuration interface will be written such that it can
be extended to support tiered and HA configurations.

### Chef Run

During the setup phase of the Chef Client run, Chef Client shall make a HTTP
GET request to the enforced recipe endpoint. If the Chef Server returns a 404
response, Chef Client will continue the Chef Client run normally. If the Chef
Server returns a 200 response, Chef Client will store the recipe file in its
cache directory. Chef Client will then evaluate and converge the recipe using a
mechanism to be decided.

One possible implementation is to add the recipe to the list of
`specific_recipes` which is currently populated only via CLI arguments to
`chef-client --local-mode`. In this case, enforced recipes would be evaluated
and converged after the primary run list.