<?php defined('BX_DOL') or die('hack attempt');
/**
 * Copyright (c) UNA, Inc - https://una.io
 * MIT License - https://opensource.org/licenses/MIT
 *
 * @defgroup    Developer Developer
 * @ingroup     UnaModules
 *
 * @{
 */

class BxDevPolyglot extends BxTemplStudioPolyglot
{
    protected $oModule;
    protected $aParams;
    protected $aMenuItems;
    protected $aGridObjects;

    function __construct($aParams)
    {
        parent::__construct(isset($aParams['page']) ? $aParams['page'] : '');

        $this->bPageMenuTitle = false;

        $this->aParams = $aParams;
        $this->sSubpageUrl = $this->aParams['url'] . '&pgt_page=';

        $this->oModule = BxDolModule::getInstance('bx_developer');

        $this->aMenuItems = false;

        $this->aGridObjects = [
            'manage' => $this->oModule->_oConfig->getObject('grid_pgt_manage'),
        ];
    }

    function getPageCss()
    {
        $this->oModule->_oTemplate->addStudioCss(array('polyglot.css'));
        return parent::getPageCss();
    }

    function getPageJs()
    {
        $this->oModule->_oTemplate->addStudioJs(array('polyglot.js'));
        return parent::getPageJs();
    }

    function getPageJsClass()
    {
        return $this->oModule->_oConfig->getJsClass('polyglot');
    }

    function getPageJsObject()
    {
        return $this->oModule->_oConfig->getJsObject('polyglot');
    }

    function getPageJsCode($aOptions = array(), $bWrap = true)
    {
        $aOptions = array_merge($aOptions, array(
            'sActionUrl' => BX_DOL_URL_ROOT . $this->oModule->_oConfig->getBaseUri(),
            'sPolyglotUrl' => BX_DOL_URL_STUDIO . 'polyglot.php',
            'sObjName' => $this->getPageJsObject(),
            'sAnimationEffect' => $this->oModule->_oConfig->getAnimationEffect(),
            'iAnimationSpeed' => $this->oModule->_oConfig->getAnimationSpeed()
        ));

        return parent::getPageJsCode($aOptions, $bWrap);
    }

    protected function getManager()
    {
        return $this->getGrid($this->aGridObjects['manage']);
    }
}
/** @} */
