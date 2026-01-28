// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Example} from "../src/Example.sol";

contract DeployScript is Script {
    function run() external {
        // Direcciones de los contratos de Uniswap V4 en la red que uses
        // Estas son de ejemplo, necesitas las direcciones reales
        address universalRouter = 0x492E6456D9528771018DeB9E87ef7750EF184104; // Dirección del UniversalRouter
        address poolManager = 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408;     // Dirección del PoolManager
        address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;         // Dirección de Permit2

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        Example example = new Example(
            universalRouter,
            poolManager,
            permit2
        );
        
        vm.stopBroadcast();
        
        console.log("Example deployed at:", address(example));
    }
}