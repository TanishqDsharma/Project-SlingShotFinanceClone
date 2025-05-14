// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;


interface ISlingShot{
    struct TradeFormat{
        address moduleAddress;
        bytes encodedCallData;
    }
}