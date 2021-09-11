pragma solidity >=0.4.21 <0.7.0;

contract HelloContract {
   function hello() public pure returns (string memory) {
      return "Hello World!";
   }
}