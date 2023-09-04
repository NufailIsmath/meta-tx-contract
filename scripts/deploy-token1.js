const hre = require("hardhat");

async function main() {
    const Token1 = await hre.ethers.getContractFactory("Token1");
    const token1 = await Token1.deploy();

    await token1.deployed();

    console.log("Token 1 contract deployed at: ", token1.address);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});