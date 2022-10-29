#include <iostream>
#include <propidl.h>
#include <objidl.h>

#include <stdio.h>
#include <windows.h>
#include <ole2.h>

// #pragma comment( lib, "ole32.lib" )

IPropertyStorage* CreatePropertySetInStorage( IStorage *pStg, const FMTID &fmtid )
{
    HRESULT hr = S_OK;
    IPropertySetStorage *pPropSetStg = NULL;
    IPropertyStorage *pPropStg = NULL;

    try
    {
        hr = StgCreatePropSetStg( pStg, 0 /*reserved*/, 
                                  &pPropSetStg );
        if( FAILED(hr) ) 
            throw L"Failed StgCreatePropSetStg (%08x)";

        hr = pPropSetStg->Create( fmtid, NULL,
            PROPSETFLAG_DEFAULT,
            STGM_CREATE | STGM_READWRITE | STGM_SHARE_EXCLUSIVE,
            &pPropStg );
        if( FAILED(hr) ) 
            throw L"Failed IPropertySetStorage::Create (%08x)";

        // Success. The caller must now call Release on both
        // pPropSetStg and pStg.

    }
    catch( const WCHAR *pwszError )
    {
        wprintf( L"Error: %s (%08x)\n", pwszError, hr );
    }

    if( NULL != pPropSetStg )
        pPropSetStg->Release();

    return( pPropStg );
}


void main(int argc, char *argv[]) {
    HRESULT hr = S_OK;
    IStorage *pStg = NULL;
    IPropertyStorage *pPropStg = NULL;

    try
    {
        // Create an object with an IStorage interface. It is not 
        // necessary that it be a system-provided storage, such as 
        // that obtained by this call.  Any object that implements 
        // IStorage can be used.

        hr = StgCreateStorageEx( NULL,  // Create a temporary storage.
                                 STGM_CREATE
                                    | STGM_READWRITE
                                    | STGM_SHARE_EXCLUSIVE,
                                 STGFMT_STORAGE,
                                 0, NULL, NULL,
                                 IID_IStorage,
                                 reinterpret_cast<void**>(&pStg) );
        if( FAILED(hr) ) throw L"Failed StgCreateStorageEx";

        // Get and use an IPropertySetStorage that represents this 
        // IStorage.

        pPropStg = CreatePropertySetInStorage( pStg, FMTID_SummaryInformation );
        if( NULL == pPropStg ) 
           throw L"Failed CreatePropertySetInStorage";

        // Here you could call IPropertyStorage methods, such as 
        // WriteMultiple andReadMultiple, using the pPropStg pointer.

        printf( "Success\n" );
    }    
    catch( const WCHAR *pwszError )
    {
        wprintf( L"Error: %s (%08x)\n", pwszError, hr );
    }

    if( NULL != pPropStg )
        pPropStg->Release();
    if( NULL != pStg )
        pStg->Release();

}

