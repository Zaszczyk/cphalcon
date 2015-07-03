
/*
 +------------------------------------------------------------------------+
 | Phalcon Framework                                                      |
 +------------------------------------------------------------------------+
 | Copyright (c) 2011-2015 Phalcon Team (http://www.phalconphp.com)       |
 +------------------------------------------------------------------------+
 | This source file is subject to the New BSD License that is bundled     |
 | with this package in the file docs/LICENSE.txt.                        |
 |                                                                        |
 | If you did not receive a copy of the license and are unable to         |
 | obtain it through the world-wide-web, please send an email             |
 | to license@phalconphp.com so we can send you a copy immediately.       |
 +------------------------------------------------------------------------+
 | Authors: Andres Gutierrez <andres@phalconphp.com>                      |
 |          Eduar Carvajal <eduar@phalconphp.com>                         |
 +------------------------------------------------------------------------+
 */

namespace Phalcon\Mvc\Model\MetaData;

use Phalcon\Mvc\Model\MetaData;
use Phalcon\Mvc\Model\MetaDataInterface;
use Phalcon\Cache\Backend\Libmemcached;
use Phalcon\Cache\Frontend\Data as FrontendData;
use Phalcon\Mvc\Model\Exception;

/**
 * Phalcon\Mvc\Model\MetaData\Libmemcached
 *
 * Stores model meta-data in the Memcache.
 *
 * By default meta-data is stored for 48 hours (172800 seconds)
 *
 *
 *<code>
 *	$metaData = new Phalcon\Mvc\Model\Metadata\Libmemcached(array(
 *		'servers' => array(
 *         array('host' => 'localhost', 'port' => 11211, 'weight' => 1),
 *     ),
 *     'client' => array(
 *         Memcached::OPT_HASH => Memcached::HASH_MD5,
 *         Memcached::OPT_PREFIX_KEY => 'prefix.',
 *     ),
 *    'lifetime' => 3600,
 *    'prefix' => 'my_'
 *	));
 *</code>
 */
class Libmemcached extends MetaData implements MetaDataInterface
{

	protected _prefix = "";

	protected _ttl = 172800;

	protected _memcache = null;

	/**
	 * Phalcon\Mvc\Model\MetaData\Libmemcached constructor
	 *
	 * @param array options
	 */
	public function __construct(options = null)
	{
		var ttl, prefix;

		if typeof options != "array" {
			let options = [];
		}

		if !isset options["servers"] {
			throw new Exception("No servers given in options");
		}

		if fetch ttl, options["lifetime"] {
			let this->_ttl = ttl;
		}

		if fetch prefix, options["prefix"] {
			let this->_prefix = prefix;
			unset options["prefix"];
		}

		if !isset options["statsKey"] {
			let options["statsKey"] = "_PHCM_MM";
		}

		let this->_memcache = new Libmemcached(
			new FrontendData(["lifetime": this->_ttl]),
			options
		);

		let this->_metaData = [];
	}

	/**
	 * Reads metadata from Memcache
	 */
	public function read(string! key) -> array | null
	{
		var data;
		
		let data = this->_memcache->get(this->_prefix . key);
		if typeof data == "array" {
			return data;
		}
		return null;
	}

	/**
	 * Writes the metadata to Memcache
	 */
	public function write(string! key, var data) -> void
	{
		this->_memcache->save(this->_prefix . key, data, this->_ttl);
	}

	/**
	 * Flush Memcache data and resets internal meta-data in order to regenerate it
	 */
	public function reset() -> void
	{
		var meta, key, prefix, realKey;

		let meta = this->_metaData;

		if typeof meta == "array" {
			let prefix = this->_prefix;

			for key, _ in meta {
				let realKey = prefix . "meta-" . key;
				
				this->_memcache->delete(realKey);
			}
		}

		parent::reset();
	}
}