/**
 * Created by ciacob on 2017-01-05.
 */
package ro.ciacob.stochastic.random {
import flash.utils.Dictionary;

public class WRPickerConfig {

        private static const USE_PREFERRED_SYNTAX : String = 'Class `WRPickerConfig` uses method chaining ' +
                'syntax. Please use `WRPickerConfig.$create()` instead.';

        private var _map : Object;
        private var _index : Array;
        private var _dictionary : Dictionary;
        private var _exhaustible : Boolean;
        private var _numPicks : uint;
        private var _normalizedList : Array;
        private var _rawList : Array;
		private var _randomIntegerFunction : Function;

        public function WRPickerConfig (iLock : iLock = null) {
            if (iLock == null) {
                throw (new Error (USE_PREFERRED_SYNTAX));
            }
            _map = [];
            _index = [];
            _dictionary = new Dictionary;
            _exhaustible = false;
            _numPicks = 1;
        }

        public static function $create () : WRPickerConfig {
            return new WRPickerConfig (iLock.$set());
        }

        public function $add (element : Object, weight : int) : WRPickerConfig {
            if (element in _dictionary) {
                change (element, weight);
                return this;
            }
            var e : Entry = new Entry (element, weight);
            var uid : uint = e.uid;
            _map[uid] = e;
            _dictionary[element] = e;
            _index.push (uid);
            _normalizedList = null;
            return this;
        }

        public function $setExhaustible (state : Boolean) : WRPickerConfig {
            _exhaustible = state;
            return this;
        }

        public function $setNumPicks (times : uint) : WRPickerConfig {
            _numPicks = Math.max (1, times);
            return this;
        }
		
		/**
		 * Allows you to specify your own "randomInteger()" function, maybe one made available by a seeded
		 * PRG class. If that is the case, you will properly seed that class outside `WeightedRandomPicker`
		 * or `WRPicker` config.
		 * 
		 * The function that you provide must have this signature:
		 * 
		 * public function myRandomIntegerFunction (limitLow : uint, limitHigh : uint) : uint
		 * 
		 * and is expected to include both limits in the returned results.
		 */
		public function $setRandomIntegerFunction (func : Function) : WRPickerConfig {
			_randomIntegerFunction = func;
			return this;
		}
		
		/**
		 * @see $setRandomIntegerFunction
		 */
		public function $unsetRandomIntegerFunction () : WRPickerConfig {
			_randomIntegerFunction = null;
			return this;
		}

        public function change (element : Object, newWeight : int) : Boolean {
            var e : Entry = _dictionary[element];
            if (!e) {
                return false;
            }
            if (e.weight != newWeight) {
                e.weight = newWeight;
                _normalizedList = null;
            }
            return true;
        }

        public function remove (element : Object) : Boolean {
            var e : Entry = _dictionary[element];
            if (!e) {
                return false;
            }
            var uid : uint = e.uid;
            delete (_dictionary[element]);
            delete (_map[uid]);
            var loc : int = _index.indexOf (uid);
            _index.splice (loc, 1);
            _normalizedList = null;
            return true;
        }

        public function get numPicks () : uint {
            return _numPicks;
        }

        public function get exhaustible () : Boolean {
            return _exhaustible;
        }

        public function get normalizedList () : Array {
            return (_normalizedList || (_normalizedList = _computeNormalizedList()));
        }
		
		public function get randomIntegerFunction () : Function {
			return _randomIntegerFunction;
		}

        private function _computeNormalizedList () : Array {

            // Separate negative from positive indices; transpose negatives into positive
            // realm and retain maximum (transposed) value
            var maxNegative : uint = 0;
            var negativeWeights : Array = [];
            var positiveWeights : Array = [];
            var ret : Array = [];
            var i : uint = 0;
            var e : Entry = null;
            var numIndices : uint = _index.length;
            var w : int = 0;
			var uid : uint = 0;
            for (i; i < numIndices; i++) {
				uid = (_index[i] as uint);
                e = (_map[uid] as Entry);
                w = e.weight;
                if (w < 0) {
                    w = Math.abs (w);
                    if (w > maxNegative) {
                        maxNegative = w;
                    }
                    negativeWeights.push ([e.source, w]);
                    continue;
                }
                positiveWeights.push ([e.source, w]);
            }

            // Reverse transposed values using their largest as a pivot
            var numNegWeights : uint = negativeWeights.length;
			if (numNegWeights != 0) {
	            var j : uint = 0;
	            var pair : Array = null;
	            var nWeight : uint = 0;
				
				// We need to also allow the "lightest" element on the list. Without
				// this step, it would have the weight of `0`, which means exclusion.
				maxNegative += 1;
				
	            for (j; j < numNegWeights; j++) {
	                pair = (negativeWeights[j] as Array);
	                nWeight = (pair[1] as uint);
	                pair[1] = (maxNegative - nWeight);
	            }
			}

            // Offset (original) positive values by the largest of the transposed values
            if (maxNegative != 0) {
				var k : uint = 0;
	            var numPosWeights : uint = positiveWeights.length;
	            var pVal : Array = null;
	            var pWeight : uint = 0;
	            for (k; k < numPosWeights; k++) {
	                pVal = (positiveWeights[k] as Array);
	                pWeight = (pVal[1] as uint);
	                pVal[1] = (maxNegative + pWeight);
	            }
			}
            ret = negativeWeights.concat (positiveWeights);
			
			// Normalize to 100 (i.e., limit granularity to 1%)
            ret.sort (_numericallyBy2ndField);
			var L : uint = 0;
			var numAll : uint = ret.length;
			pair = null;
			var weight : uint  = 0;
			var weightsSum : uint = 0;
			for (L; L < numAll; L++) {
				pair = (ret[L] as Array);
				weight = (pair[1] as uint);
				weightsSum += weight;
			}
			var M : uint = 0;
			var normWeight : uint = 0;
			for (M; M < numAll; M++) {
				pair = (ret[M] as Array);
				weight = (pair[1] as uint);
				normWeight = (Math.ceil ((weight / weightsSum) * 100) as uint);
				pair[1] = normWeight;
			}
            return ret;
        }

        private function _numericallyBy2ndField (a : Array, b: Array) : int {
            return (((a[1] as uint) - (b[1] as uint)) as int);
        }
    }
}

internal class iLock {
    public static function $set () : iLock {return new iLock };
}

internal class Entry {
    private static var _count : uint = 0;

    public var source : Object;
    public var weight : int;
    public var uid : uint;

    public function Entry (src : Object, wght : int) {
        source = src;
        weight = wght;
        uid = _count;
        _count++;
    }
}