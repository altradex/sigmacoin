pragma solidity ^ 0.4 .9;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";


contract ERC20 {
	uint public totalSupply;

	function balanceOf(address who) constant returns(uint);

	function allowance(address owner, address spender) constant returns(uint);

	function transferFrom(address from, address to, uint value) returns(bool ok);

	function approve(address spender, uint value) returns(bool ok);

	function transfer(address to, uint value) returns(bool ok);

	function convert(uint _value) returns(bool ok);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


contract SigmaToken is ERC20, usingOraclize {

	using strings
	for * ;

	bytes32 myid_;

	mapping(bytes32 => bytes32) myidList;

	uint public totalSupply = 500000000 * 100000; // total supply 500 million

	uint public counter = 0;

	mapping(address => uint) balances;

	mapping(address => mapping(address => uint)) allowed;

	address owner;

	// string usd_price_with_decimal=".02 usd per token";

	uint one_ether_usd_price;

	modifier respectTimeFrame() {
		if ((now < startBlock) || (now > endBlock)) throw;
		_;
	}

	enum State {
		created,
		gotapidata,
		wait
	}
	State state;

	// To indicate ICO status; crowdsaleStatus=0=> ICO not started; crowdsaleStatus=1=> ICO started; crowdsaleStatus=2=> ICO closed
	uint public crowdsaleStatus = 0;

	// ICO start block
	uint public startBlock;
	// ICO end block  
	uint public endBlock;

	// Name of the token
	string public constant name = "SIGMA";

	//Emit event on transferring 3TC to user when payment is received 
	event MintAndTransfer(address addr, uint value, bytes32 comment);


	// Symbol of token
	string public constant symbol = "SIGMA";
	uint8 public constant decimals = 5;

	address beneficiary_;
	uint256 benef_ether;

	// Functions with this modifier can only be executed by the owner
	modifier onlyOwner() {
		if (msg.sender != owner) {
			throw;
		}
		_;
	}

	mapping(bytes32 => address) userAddress;
	mapping(address => uint) uservalue;
	mapping(bytes32 => bytes32) userqueryID;


	event TRANS(address accountAddress, uint amount);
	event Message(string message, address to_, uint token_amount);

	event Price(string ethh);
	event valuee(uint price);

	function SigmaToken() {
		owner = msg.sender;
		balances[owner] = totalSupply;

	}

	//To start PREICO
	function PREICOstart() onlyOwner() {

		startBlock = now;

		endBlock = now + 10 days;

		crowdsaleStatus = 3;

	}

	//fallback function i.e. payable; initiates when any address transfers Eth to Contract address
	function() payable {

		beneficiary_ = msg.sender;

		benef_ether = msg.value;

		TRANS(beneficiary_, benef_ether); // doing something with the result..


		getetherpriceinUSD(msg.sender, msg.value);

	}

	function getetherpriceinUSD(address benef_add, uint256 benef_value) {

		bytes32 ID = oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");

		userAddress[ID] = benef_add;
		uservalue[benef_add] = benef_value;
		userqueryID[ID] = ID;



	}

	//  callback function called when we get USD price from oraclize query

	function __callback(bytes32 myid, string result) {
		if (msg.sender != oraclize_cbAddress()) {
			// just to be sure the calling address is the Oraclize authorized one
			throw;
		}


		var s = result.toSlice();
		strings.slice memory part;
		var usd_price_b = s.split(".".toSlice()); // part and return value is "www"
		var usd_price_a = s;
		var fina = usd_price_b.concat(usd_price_a);



		Price(fina); // doing something with the result..


		one_ether_usd_price = stringToUint(fina);

		bytes memory b = bytes(fina);

		if (b.length == 3) {
			one_ether_usd_price = stringToUint(fina) * 100;

			valuee(one_ether_usd_price);
		}

		if (b.length == 4) {
			one_ether_usd_price = stringToUint(fina) * 10;
			valuee(one_ether_usd_price);
		}
		uint no_of_token;
		if (counter > 100000000 || now > endBlock) {
			crowdsaleStatus = 1;
		}

		valuee(counter);

		valuee(now);
		valuee(endBlock);
		if (crowdsaleStatus == 3) {
			if ((now <= endBlock) && counter <= 100000000) {
				Price("moreless");

				if (counter >= 0 && counter <= 55000000) {
					Price("less than 55000000");
					no_of_token = ((one_ether_usd_price * uservalue[userAddress[myid]])) / (200 * 1000000000000000);
					counter = counter + no_of_token;
				} else if (counter > 55000000 && counter <= 100000000) {
					Price("more than 55000000");
					no_of_token = ((one_ether_usd_price * uservalue[userAddress[myid]])) / (500 * 1000000000000000);
					counter = counter + no_of_token;
				}

			}
		} else {
			Price("nextt");
			no_of_token = ((one_ether_usd_price * uservalue[userAddress[myid]])) / (20 * 10000000000000000);

		}


		balances[owner] -= (no_of_token * 100000);
		balances[userAddress[myid]] += (no_of_token * 100000);
		// transfer(userAddress[myid],no_of_token);
		Transfer(owner, userAddress[myid], no_of_token);

		Message("Transferred to", userAddress[myid], no_of_token);




		// new query for Oraclize!
	}


	// for balance of a account
	function balanceOf(address _owner) constant returns(uint256 balance) {
		return balances[_owner];
	}

	// Transfer the balance from owner's account to another account
	function transfer(address _to, uint256 _amount) returns(bool success) {


		if (balances[msg.sender] >= _amount &&
			_amount > 0 &&
			balances[_to] + _amount > balances[_to]) {
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
		} else {
			return false;
		}
	}



	// Send _value amount of tokens from address _from to address _to
	// The transferFrom method is used for a withdraw workflow, allowing contracts to send
	// tokens on your behalf, for example to "deposit" to a contract address and/or to charge
	// fees in sub-currencies; the command should fail unless the _from account has
	// deliberately authorized the sender of the message via some mechanism; we propose
	// these standardized APIs for approval:
	function transferFrom(
		address _from,
		address _to,
		uint256 _amount
	) returns(bool success) {
		if (balances[_from] >= _amount &&
			allowed[_from][msg.sender] >= _amount &&
			_amount > 0 &&
			balances[_to] + _amount > balances[_to]) {
			balances[_from] -= _amount;
			allowed[_from][msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(_from, _to, _amount);
			return true;
		} else {
			return false;
		}
	}

	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	function approve(address _spender, uint256 _amount) returns(bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function convert(uint _value) returns(bool ok) {
		return true;
	}

	/*	
	 * Finalize the crowdsale
	 */
	function finalize() onlyOwner {
		//Make sure IDO is running
		if (crowdsaleStatus == 0 || crowdsaleStatus == 2) throw;

		//crowdsale is ended
		crowdsaleStatus = 2;
	}

	function transfer_ownership(address to) onlyOwner {
		//if it's not the admin or the owner
		if (msg.sender != owner) throw;
		owner = to;
		balances[owner] = balances[msg.sender];
		balances[msg.sender] = 0;
	}

	/*	
	 * Failsafe drain
	 */
	function drain() onlyOwner {
		if (!owner.send(this.balance)) throw;
	}

	function stringToUint(string s) constant returns(uint result) {
		bytes memory b = bytes(s);
		uint i;
		result = 0;
		for (i = 0; i < b.length; i++) {
			uint c = uint(b[i]);
			if (c >= 48 && c <= 57) {
				result = result * 10 + (c - 48);
				// usd_price=result;

			}
		}
	}

}