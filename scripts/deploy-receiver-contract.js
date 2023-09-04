const hre = require("hardhat");

async function main() {
    const Receiver = await hre.ethers.getContractFactory("Receiver");
    const receiver = await Receiver.deploy();

    await receiver.deployed();

    console.log("Receiver contract deployed at: ", receiver.address);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});