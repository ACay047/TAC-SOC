<?php defined('BX_DOL') or die('hack attempt');
/**
 * Copyright (c) UNA, Inc - https://una.io
 * MIT License - https://opensource.org/licenses/MIT
 *
 * @defgroup    UnaStudio UNA Studio
 * @{
 */

define('BX_DOL_STUDIO_WS_ENABLED', 1);
define('BX_DOL_STUDIO_WS_DISABLED', 2);

define('BX_DOL_STUDIO_WTYPE_DEFAULT', 'library');

class BxDolStudioWidgets extends BxTemplStudioPage
{
    protected $sCacheKeyNotices = 'std_widgets_notices';

    protected $_sType;

    protected $aWidgets;
    protected $aWidgetsNotices;

    public function __construct($mixedPageName)
    {
        parent::__construct($mixedPageName);

        $this->oDb = BxDolStudioWidgetsQuery::getInstance();

        $this->_sType = BX_DOL_STUDIO_WTYPE_DEFAULT;
        if(($sType = bx_get('type')) !== false)
            $this->_sType = bx_process_input($sType);

        $this->aWidgets = array();
        $this->aWidgetsNotices = array();

        $sWType = $this->_sType != BX_DOL_STUDIO_WTYPE_DEFAULT ? $this->_sType : '';
        if(!$this->bPageMultiple) {
            $this->aWidgets = $this->oDb->getWidgets(array('type' => 'by_page_id', 'value' => $this->aPage['id'], 'wtype' => $sWType));
        }
        else
            foreach($this->aPage as $sPage => $aPage)
                $this->aWidgets[$sPage] = $this->oDb->getWidgets(array('type' => 'by_page_id', 'value' => $aPage['id'], 'wtype' => $sWType));

        //--- Load Cache (Widgets' Notices)
        $oCache = $this->oDb->getDbCacheObject();
        $sCacheKey = $this->oDb->genDbCacheKey($this->sCacheKeyNotices);
        $this->aWidgetsNotices = $oCache->getData($sCacheKey);
    }

    public function updateCache()
    {
    	$aWidgets = $this->oDb->getWidgets(array('type' => 'all_with_notices'));

    	$aResult = array();
    	foreach($aWidgets as $aWidget) {
            if(BxDolService::isSerializedService($aWidget['cnt_notices'])) {
                $aService = unserialize($aWidget['cnt_notices']);
                $sNotices = BxDolService::call($aService['module'], $aService['method'], array_merge(array($aWidget), $aService['params']), $aService['class']);
            }

            $aResult[$aWidget['id']] = $sNotices;
    	}

    	$oCache = $this->oDb->getDbCacheObject();
    	$sCacheKey = $this->oDb->genDbCacheKey($this->sCacheKeyNotices);
    	return $oCache->setData($sCacheKey, $aResult);
    }
}

/** @} */
