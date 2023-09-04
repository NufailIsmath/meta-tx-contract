const hre = require("hardhat");

async function main() {
    const Token3 = await hre.ethers.getContractFactory("Token3");
    const token3 = await Token3.deploy();

    await token3.deployed();

    console.log("Token 3 contract deployed at: ", token3.address);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});