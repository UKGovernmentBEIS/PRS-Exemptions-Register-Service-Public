# Private Rented Sector Exemptions Register (PRSE)

This repo contains the source code for the Private Rented Sector Exemptions Register (PRSE) service, a UK government digital service that enables landlords and local authorities to manage energy efficiency exemptions for private rental properties.

The Minimum Energy Efficiency Regulations (the Regulations) apply to all privately rented properties in England and Wales which are legally required to have an Energy Performance Certificate (EPC), and which are let on a relevant tenancy type.

The PRS Exemptions Register is for properties which:
* are legally required to have an EPC
* are let on a relevant tenancy type
* cannot be improved to meet the minimum standard of EPC band E for one of the reasons set out below

Where an exemption applies, the exemption must be registered by the landlord (or an agent for the landlord) before it can be relied on; this registration is made on a self-certification basis and an exemption will apply from the point at which it is registered.

Where an EPC F or G rated privately rented property is not covered by the Regulations, for example a property which is not legally required to have an EPC, or one not let on a relevant tenancy type, an exemption will not be required. In addition, properties which are covered by the Regulations and which have been improved to a minimum of EPC E will not need to be registered on the Register.

This service is build on Salesforce and split across 3 Experience Cloud portals and some backend Salesforce customisation.
The portals are as following:
* **Exemptions Register:** Allowing landlords or agents to register, view, update, and end exemptions
* **Local Authority Portal:** Allowing local authorities to review and approve, request additional information, or end exemptions as well as register penalties against a property if necessary
* **Public Portal:** Allowing any members of the public to search for exemptions and penalties for properties

The service contains integrations to the OSPlaces API for address lookups, Energy Performance Certificate (EPC) database for certificate retrieval, GOV.Notify for communications, and GOV.UK One Login for Single Sign On (SSO) login for landlords and local authorities.

We also depend on WithSecure for security, Digital Modus Base for error logging, and Salesforce GOV.UK Service Builder package, with some of the components having been reworked to follow best practices and GOV.UK Design System standards.

The service uses a mix of Apex, Lightning Web Components (LWC), Flows, and Experience Cloud sites to deliver a secure, responsive public-facing interface with GOV.UK Design System styling.

The folder structure follows standards Salesforce repo structure with the bulk of the service being inside the classes, digitalExperiences, flows, lwc, test all associated Apex tests, and scripts for helper functions.

`MockProvider` class implementes the standard `System.StubProvider` and is used for mocking in tests throughout the service.

```
├───force-app
│   └───main
│       └───default
│           ├───classes
│           │   ├───GovNotify
│           │   ├───OneLogin
│           │   └───OSPlaces
│           ├───customMetadata
│           ├───digitalExperienceConfigs
│           ├───digitalExperiences
│           │   └───site
│           │       ├───PRSE_Exemptions_Public_Register1
│           │       ├───PRSE_Local_Authority1
│           │       └───PRS_Exemptions_Register1
│           ├───lwc
│           └───test
└───scripts
```

## Requirements and develoment flow:
### Requirements
* Salesforce org with:
  * Experience Cloud
  * Public Sector Solutions
  * Salesforce GOV.UK Service Builder
  * Civic Cookie Control Integration
  * Digital Modus Base

### Build
* `npm i` to install required dependencies
* `sf project deploy start --source-dir force-app` to deploy to org
* Experience cloud sites require manual publishing
* `npm run upsertExemptionTypes` to create static exemption types
* `npm run upsertPenaltyTypes` to create static penalty types
* `npm run generateLocalAuthorityAccounts` to generate local authority accounts
* `npm run insertLocalAuthorityAccounts` to insert generated local authority accounts

### Tests
* `npm test` to run jest tests
* `npm run runAllTests` to run all apex tests
