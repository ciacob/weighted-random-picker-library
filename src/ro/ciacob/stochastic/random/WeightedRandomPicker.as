package ro.ciacob.stochastic.random {
	import ro.ciacob.utils.Arrays;
	import ro.ciacob.utils.NumberUtil;
	import ro.ciacob.utils.Strings;

	public class WeightedRandomPicker {
		
		public function WeightedRandomPicker () {}


		private static const SHUFFLE_PASSES:int = 10;
		private static const NOT_ENOUGH_UNIQUE_OPTIONS : String = 'WeightedRandomPicker - Configuration Error: Cannot pick %d unique ' +
			'values from a list of %d available options. Adjust either value, or turn off the `exhaustible` flag.';

		private var _configuration : WRPickerConfig;
		private var _areDuplicatesPermitted : Boolean = false;
		private var _availableOptions : Array = [];
		private var _rafflePool : Array = [];
		private var _numDrawings : uint = 1;
		
		
		public function configure (cfg : WRPickerConfig) : void {
			_configuration = cfg;
			_rebuild ();
		}
		
		public function refill () : void {
			_compilePool();
			_shuffle();
		}
		
		/**
		 * Returns a (possibly empty) Array containing the requested number of randomly picked elements.
		 * The Array is empty when extracting dupplicates is forbidden, and the pool of drawable elements
		 * has been exausted.
		 */
		public function pick () : Array {
			var ret : Array = [];		
			if (_rafflePool.length == 0) {
				return ret;
			}
			while (ret.length < _numDrawings) {
				ret.push (_pickAnOption ());
			}
			return ret;
		}
		
		public function get exhausted () : Boolean {
			if (_areDuplicatesPermitted) {
				return false;
			}
			return (_rafflePool.length == 0);
		}

		private function get RANDOM_INTEGER () : Function {
			return (_configuration.randomIntegerFunction || NumberUtil.getRandomInteger);
		}
		
		private function _rebuild () : void {
			_numDrawings = _configuration.numPicks;
			_areDuplicatesPermitted = !_configuration.exhaustible;
			_availableOptions = _configuration.normalizedList;
			var numOptions : uint = _availableOptions.length;
			if (_numDrawings > numOptions && !_areDuplicatesPermitted) {
				throw (new ArgumentError (Strings.sprintf (NOT_ENOUGH_UNIQUE_OPTIONS, _numDrawings, numOptions)));
			}
			_compilePool();
			_shuffle();
		}

		private function _compilePool() : void {
			_rafflePool = [];
			var i : uint = 0;
			var numOptions : uint = _availableOptions.length;
			var pair : Array = null;
			var el : Object = null;
			var weight : uint = 0;
			for (i; i < numOptions; i++) {
				pair = (_availableOptions[i] as Array);
				el = (pair[0] as Object);
				weight = (pair[1] as uint);
				while (weight > 0) {
					_rafflePool.push (el);
					weight--;
				}
			}
		}

		/**
		 * We have two cases:
		 * 1) We are allowed to have duplicates in our returned set: we just pick anything, return it and exit.
		 * 2) We are NOT allowed to have duplicates, and have picked some (new kind of) element: remove all its
		 *    dupplicates from the pool (so we cannot pick the same kind of element again), return the element, and exit.
		 * 
		 * *) The third case, where we are NOT allowed to have duplicates but picked a kind of element we already have,
		 *    NEVER OCCURES, since we remove dupplicates (as described before).
		 */
		private function _pickAnOption() : Object {
			var chosenIndex : int = RANDOM_INTEGER (0, _rafflePool.length - 1);
			var picked : Object = (_rafflePool[chosenIndex] as Object);
			if (_areDuplicatesPermitted) {
				return picked;
			}
			
			var dupeIndex : uint = 0;
			while ((dupeIndex = _rafflePool.indexOf (picked)) >= 0) {
				_rafflePool.splice (dupeIndex, 1);
			}
			return picked;
		}

		private function _shuffle() : void {
			var shuffleCount : int = SHUFFLE_PASSES;
			do {
				Arrays.shuffle (_rafflePool);
			} while (--shuffleCount > 0);
		}
	}
}
