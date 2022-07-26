import NonFungibleToken from "../../../contracts/core/NonFungibleToken.cdc"
import MPoweredNFT from "../../../contracts/MPoweredNFT.cdc"

// Setup storage for MPoweredNFT on signer account
//
transaction {
    prepare(acct: AuthAccount) {
        if acct.borrow<&MPoweredNFT.Collection>(from: MPoweredNFT.collectionStoragePath) == nil {
            let collection <- MPoweredNFT.createEmptyCollection() as! @MPoweredNFT.Collection
            acct.save(<-collection, to: MPoweredNFT.collectionStoragePath)
            acct.link<&{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver}>(MPoweredNFT.collectionPublicPath, target: MPoweredNFT.collectionStoragePath)
        }
    }
}