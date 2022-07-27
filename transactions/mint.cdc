import NonFungibleToken from "../../../contracts/core/NonFungibleToken.cdc"
import MPoweredNFT from "../../../contracts/MPoweredNFT.cdc"

// Mint MPoweredNFT token to signer acct
//
transaction(name: String, description: String, image: String, unlockableContent: String, setId: UInt64, metadata: String, royalties: [MPoweredNFT.Royalty]) {
    let minter: Capability<&MPoweredNFT.Minter>
    let receiver: Capability<&{NonFungibleToken.Receiver}>

    prepare(acct: AuthAccount) {
        if acct.borrow<&MPoweredNFT.Collection>(from: MPoweredNFT.collectionStoragePath) == nil {
            let collection <- MPoweredNFT.createEmptyCollection() as! @MPoweredNFT.Collection
            acct.save(<- collection, to: MPoweredNFT.collectionStoragePath)
            acct.link<&{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver}>(MPoweredNFT.collectionPublicPath, target: MPoweredNFT.collectionStoragePath)
        }

        self.minter = MPoweredNFT.minter()
        self.receiver = acct.getCapability<&{NonFungibleToken.Receiver}>(MPoweredNFT.collectionPublicPath)
    }

    execute {
        let minter = self.minter.borrow() ?? panic("Could not borrow receiver capability (maybe receiver not configured?)")
        minter.mintSingle(recipient: self.reveiver, name: name, description: description, image: image, unlockableContent: unlockableContent, setId: setId, metadata: metadata, royalties: royalties)
	    
    }
}
