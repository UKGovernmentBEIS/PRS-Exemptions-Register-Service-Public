#!/bin/bash

#Run this if you don't have permission
#chmod +x ./scripts/shell/retrieveFlowAndExperience.sh

echo -e "\e[32mRetrieving Screen Flows\e[0m"
sf project retrieve start --metadata "Flow:PRSE_AccountRegistration" --ignore-conflicts
sf project retrieve start --metadata "Flow:PRSE_EmailHasBeenVerified" --ignore-conflicts
sf project retrieve start --metadata "Flow:PRSE_ExemptionRegistration" --ignore-conflicts
sf project retrieve start --metadata "Flow:PRSE_Registered_Exemption" --ignore-conflicts
sf project retrieve start --metadata "Flow:PRSE_PreviousExemptionsLink" --ignore-conflicts
sf project retrieve start --metadata "Flow:PRSE_UpdateExemptionLandlordInformation" --ignore-conflicts
sf project retrieve start --metadata "Flow:PRSE_UserDetailsChange" --ignore-conflicts
sf project retrieve start --metadata "Flow:PRSE_Experience_Site_Base_URL" --ignore-conflicts

echo -e "\e[32mRetrieving Digital Experience Sites\e[0m"
sf project retrieve start --metadata "DigitalExperienceBundle:site/PRS_Exemptions_Register1" --ignore-conflicts
sf project retrieve start --metadata "DigitalExperienceBundle:site/PRSE_Exemptions_Public_Register1" --ignore-conflicts
sf project retrieve start --metadata "DigitalExperienceBundle:site/PRSE_Local_Authority1" --ignore-conflicts