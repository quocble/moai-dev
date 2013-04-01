// Copyright (c) 2010-2011 Zipline Games, Inc. All Rights Reserved.
// http://getmoai.com

#include "pch.h"

#if USE_CHIPMUNK
  #include <chipmunk/chipmunk.h>
#endif

#include <moaicore/moaicore.h>

extern "C" {
	#include <zlib.h>
	#include <zlcore/ZLZipArchive.h>
}

#if MOAI_WITH_OPENSSL
	#include <openssl/conf.h>
	#include <openssl/crypto.h>

	#ifndef OPENSSL_NO_ENGINE
		#include <openssl/engine.h>
	#endif

	#ifndef OPENSSL_NO_ERR
		#include <openssl/err.h>
	#endif

	#include <openssl/ssl.h>
#endif

#if USE_ARES
	#include <ares.h>
#endif

//----------------------------------------------------------------//
// TODO: this should be part of the unit tests
static void _typeCheck () {

	// make sure our fixed size typedefs are what we think
	// they are on the current platform/compiler
	assert ( sizeof ( cc8 )	== 1 );

	assert ( sizeof ( u8 )	== 1 );
	assert ( sizeof ( u16 )	== 2 );
	assert ( sizeof ( u32 )	== 4 );
	assert ( sizeof ( u64 )	== 8 );
	
	assert ( sizeof ( s8 )	== 1 );
	assert ( sizeof ( s16 )	== 2 );
	assert ( sizeof ( s32 )	== 4 );
	assert ( sizeof ( s64 )	== 8 );
}

//================================================================//
// moaicore
//================================================================//

class MOAIPropFoo :
	public MOAITransform,
	public MOAIColor {
private:

	friend class MOAIPartition;
	friend class MOAIPartitionCell;
	friend class MOAIPartitionLevel;

	MOAIPartition*				mPartition;
	MOAIPartitionCell*			mCell;
	
	// this is only for debug draw
	MOAIPartitionLevel*			mLayer;
	
	USLeanLink < MOAIPropFoo* >	mLinkInCell;
	MOAIPropFoo*					mNextResult;

	u32				mMask;
	USBox			mBounds;
	s32				mPriority;

	//----------------------------------------------------------------//
	void			DrawGrid			( int subPrimID );
	void			DrawItem			();

protected:

	u32										mFlags;

	MOAILuaSharedPtr < MOAIDeck >			mDeck;
	MOAILuaSharedPtr < MOAIDeckRemapper >	mRemapper;
	u32										mIndex;
	
	MOAILuaSharedPtr < MOAIGrid >			mGrid;
	USVec2D									mGridScale;
	
	// TODO: these should all be attributes
	MOAILuaSharedPtr < MOAIShader >			mShader;
	MOAILuaSharedPtr < MOAIGfxState >		mTexture;
	MOAILuaSharedPtr < MOAITransformBase >	mUVTransform;
	MOAILuaSharedPtr < MOAIScissorRect >	mScissorRect;
	
	int										mCullMode;
	int										mDepthTest;
	bool									mDepthMask;
	MOAIBlendMode							mBlendMode;

	USBox									mBoundsOverride;

	//----------------------------------------------------------------//
	//u32				GetFrameFitting			( USBox& bounds, USVec3D& offset, USVec3D& scale );
	void			GetGridBoundsInView		( MOAICellCoord& c0, MOAICellCoord& c1 );
	virtual u32		GetPropBounds			( USBox& bounds ); // get the prop bounds in model space
	void			LoadGfxState			();
	void			UpdateBounds			( u32 status );
	void			UpdateBounds			( const USBox& bounds, u32 status );

public:

	DECL_LUA_FACTORY ( MOAIPropFoo )
	DECL_ATTR_HELPER ( MOAIPropFoo )

	static const s32 UNKNOWN_PRIORITY	= 0x80000000;
	static const int NO_SUBPRIM_ID		= 0xffffffff;

	enum {
		BOUNDS_EMPTY,
		BOUNDS_GLOBAL,
		BOUNDS_OK,
	};

	enum {
		ATTR_INDEX,
		ATTR_PARTITION,
		ATTR_SHADER,
		ATTR_BLEND_MODE,
		
		ATTR_LOCAL_VISIBLE,		// direct access to the prop's 'local' visbility setting
		ATTR_VISIBLE,			// read only - reflects the composite state of visibility
		INHERIT_VISIBLE,		// used to *pull* parent visibility via inheritance
		
		INHERIT_FRAME,
		FRAME_TRAIT,
		
		TOTAL_ATTR,
	};

	enum {
		CAN_DRAW					= 0x01,
		CAN_DRAW_DEBUG				= 0x02,
		CAN_GATHER_SURFACES			= 0x04,
	};

	enum {
		FLAGS_OVERRIDE_BOUNDS		= 0x01,
		FLAGS_EXPAND_FOR_SORT		= 0x02,
		FLAGS_BILLBOARD				= 0x04,
		FLAGS_LOCAL_VISIBLE			= 0x08,
		FLAGS_VISIBLE				= 0x10, // this is a composite of FLAGS_LOCAL_VISIBLE plus the parent's ATTR_VISIBLE
	};

	static const u32 DEFAULT_FLAGS	= FLAGS_LOCAL_VISIBLE | FLAGS_VISIBLE;

	GET_SET ( u32, Index, mIndex )
	GET_SET ( u32, Mask, mMask )
	GET ( s32, Priority, mPriority )
	GET ( MOAIPartition*, Partition, mPartition )
	
	GET ( MOAIDeck*, Deck, mDeck )
	GET ( MOAIDeckRemapper*, Remapper, mRemapper )
	GET ( USBox, Bounds, mBounds )
	GET ( USVec3D, BoundsMax, mBounds.mMax )
	GET ( USVec3D, BoundsMin, mBounds.mMin )

	//----------------------------------------------------------------//
	void				AddToSortBuffer			( MOAIPartitionResultBuffer& buffer, u32 key = 0 );
	bool				ApplyAttrOp				( u32 attrID, MOAIAttrOp& attrOp, u32 op );
	virtual void		Draw					( int subPrimID );
	virtual void		DrawDebug				( int subPrimID );
	virtual void		GatherSurfaces			( MOAISurfaceSampler2D& sampler );
	MOAIPartition*		GetPartitionTrait		();
	bool				GetCellRect				( USRect* cellRect, USRect* paddedRect = 0 );
	virtual void		GetCollisionShape		( MOAICollisionShape& shape );
	virtual bool		Inside					( USVec3D vec, float pad );
						MOAIPropFoo				();
	virtual				~MOAIPropFoo				();
	void				OnDepNodeUpdate			();
	void				RegisterLuaClass		( MOAILuaState& state );
	void				RegisterLuaFuncs		( MOAILuaState& state );
	void				Render					();
	void				SerializeIn				( MOAILuaState& state, MOAIDeserializer& serializer );
	void				SerializeOut			( MOAILuaState& state, MOAISerializer& serializer );
	void				SetPartition			( MOAIPartition* partition );
	void				SetVisible				( bool visible );
};

//================================================================//
// MOAIPropFoo
//================================================================//

//----------------------------------------------------------------//
void MOAIPropFoo::AddToSortBuffer ( MOAIPartitionResultBuffer& buffer, u32 key ) {
}

//----------------------------------------------------------------//
bool MOAIPropFoo::ApplyAttrOp ( u32 attrID, MOAIAttrOp& attrOp, u32 op ) {
	return false;
}

//----------------------------------------------------------------//
void MOAIPropFoo::Draw ( int subPrimID ) {
	UNUSED ( subPrimID );
}

//----------------------------------------------------------------//
void MOAIPropFoo::DrawDebug ( int subPrimID ) {
	UNUSED ( subPrimID );
}

//----------------------------------------------------------------//
void MOAIPropFoo::DrawGrid ( int subPrimID ) {
}

//----------------------------------------------------------------//
void MOAIPropFoo::DrawItem () {
}

//----------------------------------------------------------------//
void MOAIPropFoo::GatherSurfaces ( MOAISurfaceSampler2D& sampler ) {
}

//----------------------------------------------------------------//
bool MOAIPropFoo::GetCellRect ( USRect* cellRect, USRect* paddedRect ) {
	
	return false;
}

//----------------------------------------------------------------//
void MOAIPropFoo::GetCollisionShape ( MOAICollisionShape& shape ) {
	UNUSED ( shape );
}

//----------------------------------------------------------------//
void MOAIPropFoo::GetGridBoundsInView ( MOAICellCoord& c0, MOAICellCoord& c1 ) {
}

//----------------------------------------------------------------//
u32 MOAIPropFoo::GetPropBounds ( USBox& bounds ) {
	
	printf ( "GET BOUNDS\n" );
	
	this->mGrid.Set ( *this, 0 );
	this->mDeck.Set ( *this, 0 );
	
	if ( this->mFlags & FLAGS_OVERRIDE_BOUNDS ) {
		bounds = this->mBoundsOverride;
		return BOUNDS_OK;
	}
	
	if ( this->mGrid ) {
		
		//if ( this->mGrid->GetRepeat ()) {
		//	return BOUNDS_GLOBAL;
		//}
		
		USRect rect = this->mGrid->GetBounds ();
		bounds.Init ( rect.mXMin, rect.mYMin, rect.mXMax, rect.mYMax, 0.0f, 0.0f );
		//return this->mGrid->GetRepeat () ? BOUNDS_GLOBAL : BOUNDS_OK;
	}
	else if ( this->mDeck ) {
	
		//bounds = this->mDeck->GetBounds ( this->mIndex, this->mRemapper );
		//return BOUNDS_OK;
	}
	
	return BOUNDS_EMPTY;
}

//----------------------------------------------------------------//
MOAIPartition* MOAIPropFoo::GetPartitionTrait () {

	return this->mPartition;
}

//----------------------------------------------------------------//
bool MOAIPropFoo::Inside ( USVec3D vec, float pad ) {

	USAffine3D worldToLocal = this->GetWorldToLocalMtx ();
	worldToLocal.Transform ( vec );

	USBox bounds;

	u32 status = this->GetPropBounds ( bounds );
	
	if ( status == BOUNDS_GLOBAL ) return true;
	if ( status == BOUNDS_EMPTY ) return false;
	
	bounds.Bless ();
	bounds.Inflate ( pad );
	return bounds.Contains ( vec );
}

//----------------------------------------------------------------//
void MOAIPropFoo::LoadGfxState () {
}

//----------------------------------------------------------------//
MOAIPropFoo::MOAIPropFoo () {
}

//----------------------------------------------------------------//
MOAIPropFoo::~MOAIPropFoo () {
}

//----------------------------------------------------------------//
void MOAIPropFoo::OnDepNodeUpdate () {
	
	MOAIColor::OnDepNodeUpdate ();
	MOAITransform::OnDepNodeUpdate ();
	
	USBox propBounds;
	u32 propBoundsStatus = this->GetPropBounds ( propBounds );
	
	// update the prop location in the partition
	propBounds.Transform ( this->mLocalToWorldMtx );
	this->UpdateBounds ( propBounds, propBoundsStatus );
	
	bool visible = USFloat::ToBoolean ( this->GetLinkedValue ( MOAIPropFooAttr::Pack ( INHERIT_VISIBLE ), 1.0f ));
	this->mFlags = visible && ( this->mFlags & FLAGS_LOCAL_VISIBLE ) ? this->mFlags | FLAGS_VISIBLE : this->mFlags & ~FLAGS_VISIBLE ;	
}

//----------------------------------------------------------------//
void MOAIPropFoo::RegisterLuaClass ( MOAILuaState& state ) {
}

//----------------------------------------------------------------//
void MOAIPropFoo::RegisterLuaFuncs ( MOAILuaState& state ) {
}

//----------------------------------------------------------------//
void MOAIPropFoo::Render () {

	this->Draw ( MOAIPropFoo::NO_SUBPRIM_ID );
}

//----------------------------------------------------------------//
void MOAIPropFoo::SerializeIn ( MOAILuaState& state, MOAIDeserializer& serializer ) {
	
	this->mDeck.Set ( *this, serializer.MemberIDToObject < MOAIDeck >( state.GetField < uintptr >( -1, "mDeck", 0 )));
	this->mGrid.Set ( *this, serializer.MemberIDToObject < MOAIGrid >( state.GetField < uintptr >( -1, "mGrid", 0 )));
}

//----------------------------------------------------------------//
void MOAIPropFoo::SerializeOut ( MOAILuaState& state, MOAISerializer& serializer ) {
	
	state.SetField ( -1, "mDeck", serializer.AffirmMemberID ( this->mDeck ));
	state.SetField ( -1, "mGrid", serializer.AffirmMemberID ( this->mGrid ));
}

//----------------------------------------------------------------//
void MOAIPropFoo::SetPartition ( MOAIPartition* partition ) {
}

//----------------------------------------------------------------//
void MOAIPropFoo::SetVisible ( bool visible ) {

	this->mFlags = visible ? this->mFlags | FLAGS_LOCAL_VISIBLE : this->mFlags & ~FLAGS_LOCAL_VISIBLE;
	this->ScheduleUpdate ();
}

//----------------------------------------------------------------//
void MOAIPropFoo::UpdateBounds ( u32 status ) {

	USBox bounds;
	bounds.Init ( 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f );

	if ( status == BOUNDS_OK ) {
		status = BOUNDS_EMPTY;
	}
	this->UpdateBounds ( bounds, status );
}

//----------------------------------------------------------------//
void MOAIPropFoo::UpdateBounds ( const USBox& bounds, u32 status ) {
}





//----------------------------------------------------------------//
void moaicore::InitGlobals ( MOAIGlobals* globals ) {

	MOAIGlobalsMgr::Set ( globals );
	
	if ( !globals ) {
	
		printf ( "THIS CODE IS NEVER EXECUTED\n" );
		
		static MOAIGlyphCacheBase* glyphCache = new MOAIStaticGlyphCache (); // comment out this like and the sample will run
	}
	
	printf ( "THIS CODE IS TOTALLY EXECUTED\n" );
	
	static MOAIPropFoo* prop = new MOAIPropFoo ();
}

//----------------------------------------------------------------//
void moaicore::SystemFinalize () {

	MOAIGlobalsMgr::Finalize ();
	
	#if MOAI_WITH_LIBCURL
		curl_global_cleanup ();
	#endif
	
	#if MOAI_WITH_OPENSSL
	
		#ifndef OPENSSL_NO_ENGINE
			ENGINE_cleanup ();
		#endif
		
		CONF_modules_unload ( 1 );
		
		#ifndef OPENSSL_NO_ERR
			ERR_free_strings ();
		#endif
		
		EVP_cleanup ();
		CRYPTO_cleanup_all_ex_data ();
	#endif
	
	zl_cleanup ();
}

//----------------------------------------------------------------//
void moaicore::SystemInit () {

	_typeCheck ();
		
	srand (( u32 )time ( 0 ));
	zl_init ();
	
	#if MOAI_WITH_OPENSSL
		SSL_load_error_strings ();
		SSL_library_init ();
	#endif

	#if USE_ARES
		ares_set_default_dns_addr ( 0x08080808 );
	#endif
	
	#if MOAI_WITH_LIBCURL
		curl_global_init ( CURL_GLOBAL_WIN32 | CURL_GLOBAL_SSL );
	#endif
	
	#if MOAI_WITH_CHIPMUNK
		cpInitChipmunk ();
	#endif
}
