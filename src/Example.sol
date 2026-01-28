// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UniversalRouter} from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import {Commands} from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IV4Router} from "@uniswap/v4-periphery/src/interfaces/IV4Router.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

contract Example {
    using StateLibrary for IPoolManager;

    UniversalRouter public immutable ROUTER;
    IPoolManager public immutable POOL_MANAGER;
    IPermit2 public immutable PERMIT2;

    constructor(address _router, address _poolManager, address _permit2) {
        ROUTER = UniversalRouter(payable(_router));
        POOL_MANAGER = IPoolManager(_poolManager);
        PERMIT2 = IPermit2(_permit2);
    }

    function approveTokenWithPermit2(
        address token,
        uint160 amount,
        uint48 expiration
    ) external {
        IERC20(token).approve(address(PERMIT2), type(uint256).max);
        PERMIT2.approve(token, address(ROUTER), amount, expiration);
    }

    function swapExactInputSingle(
        PoolKey calldata key, // Struct PoolKey que identifica el pool v4
        uint128 amountIn, // Cantidad exacta de tokens a intercambiar
        uint128 minAmountOut // Cantidad mínima de tokens de salida esperada
    ) external returns (uint256 amountOut) {
        // La implementación seguirá
        bytes memory commands = abi.encodePacked(
            bytes1(uint8(Commands.V4_SWAP))
        );

        bytes memory actions = abi.encodePacked(
            uint8(Actions.SWAP_EXACT_IN_SINGLE),
            uint8(Actions.SETTLE_ALL),
            uint8(Actions.TAKE_ALL)
        );

        bytes[] memory params = new bytes[](3);

        // Primer parámetro: configuración del swap
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: true, // true si estamos intercambiando token0 por token1
                amountIn: amountIn, // cantidad de tokens que estamos intercambiando
                amountOutMinimum: minAmountOut, // cantidad mínima que esperamos recibir
                hookData: bytes("") // no se necesitan datos de hook
            })
        );

        // Segundo parámetro: especificar tokens de entrada para el swap
        // codificar parámetros de SETTLE_ALL
        params[1] = abi.encode(key.currency0, amountIn);

        // Tercer parámetro: especificar tokens de salida del swap
        params[2] = abi.encode(key.currency1, minAmountOut);

        bytes[] memory inputs = new bytes[](1);

        // Combinar acciones y parámetros en inputs
        inputs[0] = abi.encode(actions, params);

        // Ejecutar el swap
        uint256 deadline = block.timestamp + 20;
        ROUTER.execute(commands, inputs, deadline);

        amountOut = key.currency1.balanceOf(address(this));
        require(amountOut >= minAmountOut, "Insufficient output amount");

        return amountOut;
    }

    // Agregaremos más funciones aquí
}
