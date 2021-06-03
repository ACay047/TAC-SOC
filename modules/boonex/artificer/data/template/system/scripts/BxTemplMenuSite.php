<?php defined('BX_DOL') or die('hack attempt');
/**
 * Copyright (c) UNA, Inc - https://una.io
 * MIT License - https://opensource.org/licenses/MIT
 *
 * @defgroup    UnaTemplate UNA Template Classes
 * @{
 */

/**
 * @see BxTemplMenuMoreAuto
 */
class BxTemplMenuSite extends BxTemplMenuMoreAuto
{
    protected $_sModule;
    protected $_oModule;

    protected $_bSiteMenu;

    public function __construct ($aObject, $oTemplate = false)
    {
        parent::__construct ($aObject, $oTemplate);

        $this->_sModule = 'bx_artificer';
        $this->_oModule = BxDolModule::getInstance($this->_sModule);

        $this->_sJsClassMoreAuto = 'BxArtificerMenuMoreAuto';

        $this->_bSiteMenu = $this->_sObject == 'sys_site';
    }

    public function getCode ()
    {
        $sClass = 'bx-sliding-menu-main';
        $sStyle = 'display:none';
        if($this->_bSiteMenu) {
            $sClass = 'bx-sliding-smenu-main';
            $sStyle = '';
        }

        $this->_oModule->_oTemplate->addJs(array('menu_site.js'));
        return '<div id="bx-sliding-menu-' . $this->_sObject . '" class="' . $sClass . ' bx-def-z-index-nav" style="' . $sStyle . '"><div class="bx-sliding-menu-main-cnt">' . parent::getCode() . '</div></div>';
    }
}

/** @} */