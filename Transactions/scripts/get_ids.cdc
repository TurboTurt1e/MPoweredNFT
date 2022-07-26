import NonFungibleToken from "../../../../contracts/core/NonFungibleToken.cdc"
import MPoweredNFT from "../../../../contracts/MPoweredNFT.cdc"

// Take MPoweredNFT ids by account address
//
pub fun main(address: Address): [UInt64]? {
    let collection = getAccount(address)
        .getCapability(MPoweredNFT.collectionPublicPath)
        .borrow<&{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver}>()
        ?? panic("NFT Collection not found")
    return collection.getIDs()
}