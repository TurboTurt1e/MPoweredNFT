import NonFungibleToken from 0x02
import LicensedNFT from 0x03
import MetadataViews from 0x04

// MPoweredNFT contract
//
pub contract MPoweredNFT : NonFungibleToken, LicensedNFT {

    // MPoweredNFT Info
    pub var totalSupply: UInt64
    pub var name: String
    pub var description: String
    pub var image: MetadataViews.IPFSFile
    access(account) var maxNumEditions: UInt16
    pub var publicMinting: Bool
    pub var nextLimitedEdition: UInt64
    pub var nextSetId: UInt64
    pub var nextMetadataId: UInt64
    //pub var nextSeriesId: UInt32
    pub let ipfsCID: String?
    pub let dateCreated: UFix64
	
    // dictionary of SetData structs
    access(self) var setDatas: {UInt64: SetData}
    // dictionary of metadata structs	
    access(account) let metadatas: {UInt64: NFTMetadata}

    // Paths
    pub let collectionPublicPath: PublicPath
    pub let collectionStoragePath: StoragePath
    pub let minterPublicPath: PublicPath
    pub let minterStoragePath: StoragePath
    pub let administratorStoragePath: StoragePath
	
    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub event Mint(id: UInt64, creator: Address, metadata: {String:String}, royalties: [LicensedNFT.Royalty])
    pub event Destroy(id: UInt64)

    pub event SetCreated(setId: UInt64)
    // Emitted when a Set is locked, meaning NFTs cannot be added
    pub event SetLocked(setId: UInt64)


    // A data structure that contains metadata fields for a single NFT
    pub struct NFTMetadata 
    {
	pub let id: UInt64
	pub let name: String
	pub let description: String
	pub let creator: Address

	pub let image: MetadataViews.IPFSFile
	pub let limitedEdition: UInt64
	pub let edition: UInt16
	pub let editionSize: UInt16
	pub let setId: UInt64
	pub var metadata: {String: AnyStruct}
		

	init(name: String, description: String, creatorAddress: Address, image: String, unlockableContent: String, setId: UInt64, metadata: {String: AnyStruct}, limitedEdition: UInt64, edition: UInt16, editionSize: UInt16, ) {

        	self.id = MPoweredNFT.nextMetadataId
        	self.name = name
        	self.description = description
        	self.creator = creatorAddress
			self.setId = setId 

        	assert(image.length > 0, message: "NFT must contain an IPFS hash string")
        	//self.image = image
		self.image = MetadataViews.IPFSFile(
			cid: MPoweredNFT.ipfsCID!,
			path: image
		)

        	self.limitedEdition = limitedEdition
		self.edition = edition
        	self.editionSize = editionSize
		self.metadata = metadata
		MPoweredNFT.nextMetadataId = MPoweredNFT.nextMetadataId + 1
      }
    }

    //	
    pub struct CollectionInfo {
	pub let name: String
	pub let description: String
	pub let image: MetadataViews.IPFSFile
	pub let dateCreated: UFix64
	pub let totalSupply: UInt64
	pub let ipfsCID: String?
	pub let publicMinting: Bool
	pub let metadatas: {UInt64: NFTMetadata}
	pub let setDatas: {UInt64: SetData}
	pub let maxNumEditions: UInt16
	
		
	init() 
	{
		self.name = MPoweredNFT.name
		self.description = MPoweredNFT.description
		self.image = MPoweredNFT.image
		self.dateCreated = MPoweredNFT.dateCreated
		self.totalSupply = MPoweredNFT.totalSupply
		self.ipfsCID = MPoweredNFT.ipfsCID
		self.publicMinting = MPoweredNFT.publicMinting
		self.metadatas = MPoweredNFT.getNFTMetadatas()
		self.setDatas = MPoweredNFT.getSetDatas()
		self.maxNumEditions = MPoweredNFT.maxNumEditions
			
	}
    }
	
    //

    // Publically available data and functions for the NFT
    pub resource interface MPoweredNFTPublic {
        pub let id: UInt64
        pub fun getMetadata(): NFTMetadata
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, MPoweredNFTPublic  {
    	pub let id: UInt64
	pub let name: String
    	pub let description: String
        pub let creator: Address
	pub let image: String
	pub let limitedEdition: UInt64
	pub let edition: UInt16
	pub let editionSize: UInt16
	pub let setId: UInt64
		
	access(self) let unlockableContent: String
        // access(self) let metadata: {String:String}
        access(self) let licensedRoyalties: [LicensedNFT.Royalty]

        //access(self) let metadataViewsRoyalties: [MetadataViews.Royalty]
        access(self) let metadata: {String: AnyStruct}

        init(id: UInt64, name: String, description: String, creator: Address, image: String, unlockableContent: String, setId: UInt64, metadata: {String: AnyStruct}, limitedEdition: UInt64, edition: UInt16, editionSize: UInt16, royalties: [LicensedNFT.Royalty]) 
	{		
		pre {
			MPoweredNFT.metadatas[id] == nil: "This NFT id already exists yet."
		}

		self.id = id
		self.name = name
		self.description = description
		self.creator = creator
		self.image = image
		self.unlockableContent = unlockableContent
		self.setId = setId
		self.metadata = metadata
		self.limitedEdition = limitedEdition
		self.edition = edition
		self.editionSize = editionSize
		self.licensedRoyalties = royalties
		//convert royalties to metadata royalties standard
		//metadataViewsRoyalties = MetadataViews.Royalty()
		MPoweredNFT.totalSupply = MPoweredNFT.totalSupply + 1
        }

        pub fun getUnlockableContent(): String {
            return self.unlockableContent
        }

		/*
        pub fun getMetadata(): {String:String} {
            return self.metadata
        }
		*/

        pub fun getRoyalties(): [LicensedNFT.Royalty] {
            return self.licensedRoyalties
        }

	pub fun getMetadata(): NFTMetadata {
		return MPoweredNFT.getNFTMetadata(self.id)!
	}

	pub fun getViews(): [Type] {
		return [
			Type<MetadataViews.Display>(),
			Type<MetadataViews.Editions>(),
			Type<MetadataViews.ExternalURL>(),
			Type<MetadataViews.NFTCollectionData>(),
			Type<MetadataViews.NFTCollectionDisplay>(),
			Type<MetadataViews.Royalties>(),
			Type<MetadataViews.Serial>(),
			Type<MetadataViews.Traits>() //,
			//Type<MetadataViews.NFTView>()
			]
	}
		
	pub fun resolveView(_ view: Type): AnyStruct? {
		switch view {
				case Type<MetadataViews.Display>():
					let metadata = self.getMetadata()
					return MetadataViews.Display(
						name: metadata.name,
						description: metadata.description,
						thumbnail: metadata.image
					)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(
						storagePath: MPoweredNFT.collectionStoragePath,
						publicPath: MPoweredNFT.collectionPublicPath,
						providerPath: MPoweredNFT.collectionPrivatePath,
						publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
						publicLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
						providerLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, NonFungibleToken.Provider}>(),
						createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
								return <- MPoweredNFT.createEmptyCollection()
						})
					)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://mpowered.nft/".concat((self.owner!.address as Address).toString()).concat("/MPoweredNFT"))
				case Type<MetadataViews.Editions>():
					// the edition number is set to self.edition
                    			// the max edition field value is set to self.editionSize
                    			let editionInfo = MetadataViews.Edition(name: self.name, number: UInt64(self.edition), max: UInt64(self.editionSize))
                    			let editionList: [MetadataViews.Edition] = [editionInfo]
                    			return MetadataViews.Editions(editionList)
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(
						file: MPoweredNFT.image,
						mediaType: "image"
					)
					return MetadataViews.NFTCollectionDisplay(
						name: MPoweredNFT.name,
						description: MPoweredNFT.description,
						externalURL: MetadataViews.ExternalURL("https://mpowered.nft/".concat((self.owner!.address as Address).toString()).concat("/MPoweredNFT")),
						squareImage: media,
						bannerImage: media,
						socials: {
							"twitter": MetadataViews.ExternalURL("https://twitter.com/mpowerednft"),
							"discord": MetadataViews.ExternalURL("https://discord.gg/mpowerednft")
						}
					)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([
						MetadataViews.Royalty(
							recepient: getAccount(0x01).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
							cut: 0.025, // 2.5% royalty on secondary sales
							description: "MPoweredNFT royalty"
						)
					])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(
						self.id
					)
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.getMetadata().metadata, excludedNames: nil)
				
				case Type<MetadataViews.NFTView>():
					return MetadataViews.NFTView(
						id: self.id,
            					uuid: self.uuid,
            					display: self.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?,
            					externalURL: self.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL?,
            					collectionData: self.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?,
            					collectionDisplay: self.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?,
            					royalties: self.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?,
            					traits: self.resolveView(Type<MetadataViews.Traits>()) as! MetadataViews.Traits?
					)
					
			}
			return nil
		}


        destroy() {
            emit Destroy(id: self.id)
        }
    }

    // Publicly available data and functions for the NFT Collection
    pub resource interface MPoweredNFTCollectionPublic {

        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
        // Get list of ids for all NFTs in the collection
        pub fun getIDs(): [UInt64]
        // Get metadata for a specific NFT
        pub fun getTokenData(id: UInt64): NFTMetadata {
			// If the result isn't nil, the id of the returned reference
        	// should be the same as the argument to the function
        	post {
        	        (result == nil) || (result.id == id):
                	    "Cannot get token data: The ID of the returned reference is incorrect"
             	}
        }
        pub fun getAllTokenData(): [NFTMetadata]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        // Function that returns reference to the whole public facing MPoweredNFT Resource
        pub fun borrowMPoweredNFT(id: UInt64): &MPoweredNFT.NFT {
            post {
                (result == nil) || (result.id == id): 
                    "Cannot borrow MPoweredNFT reference: The ID of the returned reference is incorrect"
            }
        }

    }

    // A Set is a grouping of related NFTs,
    // for instance a set of simmilarly themed artworks by an artist
    //
    // SetData is a struct that is stored in a field of the contract.
    // Anyone can query the constant information
    // about a set by calling various getters located
    pub struct SetData {

        // Unique Id for the Set
        pub let setId: UInt64

        // Name of the Set
        pub let name: String

        // Description of the Set
        pub let description: String?

        // Creator of the Set
        pub let creator: Address
		
	// Is the set locked
	pub var locked: Bool

        // Series that this Set belongs to
        //pub let series: UInt32

        init(name: String, description: String?, creator: Address) {
            pre {
                name.length > 0: "New Set name cannot be empty"
				description!.length > 0: "New Set description cannot be empty"
            }
            self.setId = MPoweredNFT.nextSetId
            self.name = name
            self.description = description
			self.creator = creator
			self.locked = false
            //self.series = series

            // Increment the setId so that it isn't used again
            MPoweredNFT.nextSetId = MPoweredNFT.nextSetId + UInt64(1)
			
            //emit SetCreated(setId: self.setId, series: self.series)
			emit SetCreated(setId: self.setId)
        }
    }



    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, LicensedNFT.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
	    pre {
                self.ownedNFTs[withdrawID] != nil : "NFT does not exist in the collection"
            }
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <- token
        }
		
	pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            // Create a new empty Collection
            var batchCollection <- create Collection()
            
            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            
            // Return the withdrawn tokens
            return <-batchCollection
        }
		
		
    pub fun deposit(token: @NonFungibleToken.NFT) {
	    pre
	    {
		self.owner?.address != nil : "deposit function Error - Owner address is nil."
	    }
            let token <- token as! @MPoweredNFT.NFT
            let id: UInt64 = token.id
            let dummy <- self.ownedNFTs[id] <- token
            destroy dummy
            emit Deposit(id: id, to: self.owner?.address)
        }


		
	pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()
            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }
            // Destroy the empty Collection
            destroy tokens
        }


        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }



        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        pub fun borrowMPoweredNFT(id: UInt64): &MPoweredNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &MPoweredNFT.NFT
            } else {
                return nil
            }
        }
		
		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nft = token as! &NFT
			return nft as &AnyResource{MetadataViews.Resolver}
		}

        pub fun getMetadata(id: UInt64): MPoweredNFT.NFTMetadata {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
            return (ref as! &MPoweredNFT.NFT).getMetadata()
        }

        pub fun getRoyalties(id: UInt64): [LicensedNFT.Royalty] {
            let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
            return (ref as! &LicensedNFT.NFT).getRoyalties()
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }
	
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }
	
	// Get information about a NFTMetadata
	pub fun getNFTMetadata(_ metadataId: UInt64): NFTMetadata? {
		return self.metadatas[metadataId]
	}

	pub fun getNFTMetadatas(): {UInt64: NFTMetadata} {
		return self.metadatas
	}

	pub fun getSetDatas(): {UInt64: SetData} {
		return self.setDatas
	}

	pub fun getCollectionInfo(): CollectionInfo {
		return CollectionInfo()
	}
	
    pub resource Minter {
	//standardize the minting parameters
        pub fun mintSingle(recipient: Capability<&{NonFungibleToken.Receiver}>, name: String, description: String, image: String, unlockableContent: String, setId: UInt64, metadata: {String:String}, royalties: [LicensedNFT.Royalty]): &NonFungibleToken.NFT {
	    pre {
			MPoweredNFT.publicMinting: "Minting is currently closed by the Administrator!"
			//check that the set being assigned was created by the minter 
			recipient != nil : "Must have a valid capability available in order to mint"
	    }
	    //let recipientAddress = recipient.owner!.address
		let ownerAddress = self.owner!.address

    	// you can only mint for sets that you created
	    //assert(recipientAddress == MPoweredNFT.setDatas[setId].values.creator, message: "Error - This is not your Set. You cannot add to this Set.")
	    assert(ownerAddress == MPoweredNFT.setDatas[setId]!.creator, message: "Error - This is not your Set. You cannot add to this Set.")
			
        let token <- create NFT (id: MPoweredNFT.totalSupply, name: name, description: description, creator: ownerAddress, image: image, unlockableContent: unlockableContent, setId: setId, metadata: metadata, limitedEdition: MPoweredNFT.nextLimitedEdition, edition: UInt16(1), editionSize: UInt16(1), royalties: royalties)

        MPoweredNFT.nextLimitedEdition = MPoweredNFT.nextLimitedEdition + 1
        let tokenRef = &token as &NonFungibleToken.NFT
        emit Mint(id: token.id, creator: ownerAddress, metadata: metadata, royalties: royalties)
        recipient.borrow()!.deposit(token: <- token)
        return tokenRef
    }
		
	// This function takes metadata arguments as well as an editionSize parameter
	// which will mint multiple NFTs with the same metadata and increasing serial numbers
	pub fun mintEditions(recipient: &MPoweredNFT.Collection{MPoweredNFTCollectionPublic}, name: String, description: String, image: String, unlockableContent: String, setId: UInt64, metadata: {String: AnyStruct}, editionSize: UInt16, royalties: [LicensedNFT.Royalty]) {
		pre {
			MPoweredNFT.publicMinting: "Minting is currently closed by the Administrator!"
			editionSize <= MPoweredNFT.maxNumEditions : "Error Unable to mint that many NFTs... cannot mint more than maxNumEditions"
			recipient != nil : "Must have a valid MPoweredNFT Collection available in order to mint"
		}
		var a = 1
		let recipientAddress = recipient.owner!.address
		let ownerAddress = self.owner!.address
		// you can only mint for sets that you created
		assert(ownerAddress == MPoweredNFT.setDatas[setId]!.creator, message: "Error - This is not your Set. You cannot add to this Set.")
		while UInt16(a) <= editionSize {
			var newNFT <- create NFT (id: MPoweredNFT.totalSupply, name: name, description: description, creator: ownerAddress, image: image, unlockableContent: unlockableContent, setId: setId, metadata: metadata, limitedEdition: MPoweredNFT.nextLimitedEdition, edition: UInt16(a), editionSize: editionSize, royalties: royalties)
			recipient.deposit(token: <-newNFT)
			a = a + 1
		}
		MPoweredNFT.nextLimitedEdition = MPoweredNFT.nextLimitedEdition + 1
			
	}
		
	// Create a new Set and store it in the setDatas mapping in the contract
        pub fun createSet(name: String, description: String?) {
		pre 
		{
			//check that the set name does not exist yet
			MPoweredNFT.setNameExists(name: name) == false : "Error - Set name already exists"
		}
		
		let ownerAddress = self.owner!.address
		
		MPoweredNFT.setDatas[MPoweredNFT.nextSetId] = SetData(name: name, description: description, creator: ownerAddress)
	}

	// Lock the set inside set mapping in the contract
        pub fun lockSet(setId: UInt64) {
		
		pre {
			//check that the setId exists already
			MPoweredNFT.setIdExists(setId:setId) == true : "Error - Set Id does not exist"

		}
			
		// get owner address
		let ownerAddress = self.owner!.address
		// you can only lock sets that you created
		assert(ownerAddress == MPoweredNFT.setDatas[setId]!.creator, message: "Error - This is not your Set. You cannot lock this Set.")

        var setData = MPoweredNFT.setDatas[setId]
		setData

	}
					
    }

    pub fun setNameExists(name: String): Bool
    {
	//check that the set name exists yet
		
	for setData in MPoweredNFT.setDatas.values {
		if name == setData.name {
			return true
		}
	}
		
		return false
    }

    pub fun setIdExists(setId: UInt64): Bool
    {
	
	//check that the set name exists yet
	
	for setData in MPoweredNFT.setDatas.values {
		if setId == setData.setId {
			return true
		}
	}
		
	return false
    }


    pub fun minter(): Capability<&Minter> {
        return self.account.getCapability<&Minter>(self.minterPublicPath)
    }

    pub resource Administrator {
		// turn public minting on/off
		pub fun toggleMinting(): Bool {
			MPoweredNFT.publicMinting = !MPoweredNFT.publicMinting
			return MPoweredNFT.publicMinting
		}
		
		// set maxNumEditions
		pub fun setMaxNumEditions(newMax: UInt16)
		{
			pre 
			{
				newMax > 0 : "setMaxNumEditions Parameter Error... Parameter must be a positive integer greater than zero."
			}
			MPoweredNFT.maxNumEditions = newMax
		}

		// create a new Administrator resource
		pub fun createAdmin(): @Administrator {
			return <- create Administrator()
		}

		pub fun changeName(newName: String) {
			MPoweredNFT.name = newName
		}

		pub fun changeDescription(newDescription: String) {
			MPoweredNFT.description = newDescription
		}

		pub fun changeImage(cid: String, path: String?) {
			MPoweredNFT.image = MetadataViews.IPFSFile(
				cid: cid,
				path: path
			)
		}
	}
	
	init(name: String, description: String, imagePath: String, publicMinting: Bool, ipfsCID: String) 
	{
		self.totalSupply = 0
		self.nextSetId = 1
		self.name = name
		self.description = description

		self.maxNumEditions = 10000
		self.nextLimitedEdition = 0
		self.collectionPublicPath = /public/MPoweredNFTCollection
		self.collectionStoragePath = /storage/MPoweredNFTCollection
		self.minterPublicPath = /public/MPoweredNFTMinter
		self.minterStoragePath = /storage/MPoweredNFTMinter
		self.administratorStoragePath = /storage/MPoweredNFTAdministrator

		self.dateCreated = getCurrentBlock().timestamp
		
		self.image = MetadataViews.IPFSFile(
			cid: ipfsCID,
			path: imagePath
		)
		self.ipfsCID = ipfsCID

		// Initialize default info
		self.publicMinting = publicMinting
		
		self.nextMetadataId = 0
		self.metadatas = {}
		self.setDatas = {}
		

		// Create minter resource and save it to storage		
        	let minter <- create Minter()
        	self.account.save(<- minter, to: self.minterStoragePath)

		// Create a public capability for the minter
        	self.account.link<&Minter>(self.minterPublicPath, target: self.minterStoragePath)

		// Create a collection resource and save it to storage
        	let collection <- MPoweredNFT.createEmptyCollection()
        	self.account.save(<- collection, to: self.collectionStoragePath)
		
		// Create a public capability for the collection
        	self.account.link<&{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver}>(self.collectionPublicPath, target: self.collectionStoragePath)

		// Create Administrator resource and save it to storage
		let admin <- create Administrator()
		self.account.save(<- admin, to: self.administratorStoragePath)

        	emit ContractInitialized()
	}
}
