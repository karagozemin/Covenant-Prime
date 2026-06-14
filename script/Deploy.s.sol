// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {CovenantVault} from "../src/CovenantVault.sol";
import {MandateEngine} from "../src/MandateEngine.sol";
import {RefusalProofRegistry} from "../src/RefusalProofRegistry.sol";
import {ActionRouter} from "../src/ActionRouter.sol";
import {MockExchange} from "../src/MockExchange.sol";
import {MockTokenizedStock} from "../src/MockTokenizedStock.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {CorporateActionModule} from "../src/CorporateActionModule.sol";
import {AuditorDisclosureModule} from "../src/AuditorDisclosureModule.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        CovenantVault vault = new CovenantVault();
        MandateEngine engine = new MandateEngine(vault);
        RefusalProofRegistry registry = new RefusalProofRegistry();
        ActionRouter router = new ActionRouter(vault, engine, registry);
        MockExchange exchange = new MockExchange();
        MockUSDC usdc = new MockUSDC();
        MockTokenizedStock mAAPL = new MockTokenizedStock("Mock Apple", "mAAPL");
        MockTokenizedStock mNVDA = new MockTokenizedStock("Mock NVIDIA", "mNVDA");
        MockTokenizedStock mTSLA = new MockTokenizedStock("Mock Tesla", "mTSLA");
        CorporateActionModule corporateActions = new CorporateActionModule();
        AuditorDisclosureModule disclosure = new AuditorDisclosureModule(vault);
        vault.setRouter(address(router));
        registry.setRouter(address(router));
        vm.stopBroadcast();

        console2.log("CovenantVault", address(vault));
        console2.log("MandateEngine", address(engine));
        console2.log("ActionRouter", address(router));
        console2.log("RefusalProofRegistry", address(registry));
        console2.log("MockExchange", address(exchange));
        console2.log("MockUSDC", address(usdc));
        console2.log("mAAPL", address(mAAPL));
        console2.log("mNVDA", address(mNVDA));
        console2.log("mTSLA", address(mTSLA));
        console2.log("CorporateActionModule", address(corporateActions));
        console2.log("AuditorDisclosureModule", address(disclosure));
    }
}
