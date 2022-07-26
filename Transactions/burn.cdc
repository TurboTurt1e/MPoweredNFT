import NonFungibleToken from "../../../contracts/core/NonFungibleToken.cdc"
import MPoweredNFT from "../../../contracts/MPoweredNFT.cdc"

// Burn MPoweredNFT on signer account by tokenId
//
transaction(tokenId: UInt64) {
    prepare(account: AuthAccount) {
        let collection = account.borrow<&MPoweredNFT.Collection>(from: MPoweredNFT.collectionStoragePath)!
        destroy collection.withdraw(withdrawID: tokenId)
    }
}