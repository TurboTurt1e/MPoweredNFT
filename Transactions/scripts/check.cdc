import NonFungibleToken from "../../../../contracts/core/NonFungibleToken.cdc"
    import MPoweredNFT from "../../../../contracts/MPoweredNFT.cdc"

    // check MPoweredNFT collection is available on given address
    //
    pub fun main(address: Address): Bool {
        return getAccount(address)
            .getCapability<&{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver}>(MPoweredNFT.collectionPublicPath)
            .check()
    }