pragma solidity >=0.4.22 <0.7.0;

// Import the interface of NetworkSLA Contract
import "./CREDITNetworkSC.sol";

// Auditor Smart Contract. 
contract AuditorPool {
    
    uint public onlineCounter = 0;
    
    enum AState { Offline, Online, Candidate, Busy }
    
    struct Auditor {
        bool registered;   // is the auditor registered 
        uint addr;        
        AState state;    //current state
        address SLAContract;    
        int8 score;   //user reputation   
    }

    mapping(address => Auditor) auditorPool;    
    address [] public auditorAddrs;  

    
    // Information for randomized AC selection function.
    struct randomSelectionInfo{
        bool valid;
        uint curBlockNum;
        uint8 blkNeed;   
    }

    mapping(address => randomSelectionInfo) SLAContractPool;   
    

    modifier checkRegister(address _register){
        require(!auditorPool[_register].registered);
        _;
    }
    
    modifier checkAuditor(address _auditor){
        require(auditorPool[_auditor].registered);
        _;
    }
    
    modifier checkSLAContract(address _sla){
        require(SLAContractPool[_sla].valid);
        _;
    }
    
    //Generate Network SLA based on agreement between MNO and User
    function genNetworkSLA() 
        public 
        returns
        (address)
    {
        address newSLAContract = new NetworkSLA(this, msg.sender, 0x0);
        SLAContractPool[newSLAContract].valid = true; 
        return newSLAContract;
    }
    
   //Check if the SLA is in a Valid State.
    function validateSLA(address _SLAContract) 
        public
        view
        returns
        (bool)
    {
        if(SLAContractPool[_SLAContract].valid)
            return true;
        else
            return false;
    }
    
    // Register an auditor in the auditor pool.
    function register() 
        public 
        checkRegister(msg.sender) 
    {
        auditorPool[msg.sender].addr = auditorAddrs.push(msg.sender) - 1;
        auditorPool[msg.sender].state = AState.Offline;
        auditorPool[msg.sender].score = 100; 
        auditorPool[msg.sender].registered = true;
    }
    
    
    function request(uint8 _blkNeed)
        public 
        returns
        (bool success)
    {
        SLAContractPool[msg.sender].curBlockNum = block.number;
        SLAContractPool[msg.sender].blkNeed = _blkNeed;
        return true;
    }
    
   
   //function for randomized Auditor Selection.

    function randomSelection(uint _N, address _MNO, address _user)
        public
        returns
        (bool success)
    {
        uint seed = 0;
        for(uint bi = 0 ; bi<SLAContractPool[msg.sender].blkNeed ; bi++)
            seed += (uint)(blockhash(SLAContractPool[msg.sender].curBlockNum + bi + 1 ));
        uint wcounter = 0;
        while(wcounter < _N){
            address sAddr = auditorAddrs[seed % auditorAddrs.length];
            
            if(auditorPool[sAddr].state == AState.Online && auditorPool[sAddr].score > 0
              && sAddr != _MNO && sAddr != _user)
            {
                auditorPool[sAddr].state = AState.Candidate;
                auditorPool[sAddr].SLAContract = msg.sender;
                onlineCounter--;
                wcounter++;
            }
            
            seed = (uint)(keccak256(abi.encodePacked(uint(seed))));
        }
        
        SLAContractPool[msg.sender].curBlockNum = 0;
        return true;
    }
    

    function release(address _auditor)
        public
        checkAuditor(_auditor)
        checkSLAContract(msg.sender)
    {
        require(auditorPool[_auditor].state == AState.Busy);
        
        require(auditorPool[_auditor].SLAContract == msg.sender);
        
        if(auditorPool[_auditor].score <= 0){
            auditorPool[_auditor].state = AState.Offline;
        }else{
            auditorPool[_auditor].state = AState.Online;
            onlineCounter++;
        }
        
    }

// to adjust the score at the end of the SLA verification.
    function scoreDecrease(address _auditor, int8 _value)
        public
        checkAuditor(_auditor)
        checkSLAContract(msg.sender)
    {
        require( _value > 0 );
        
        require(auditorPool[_auditor].SLAContract == msg.sender);
        
        auditorPool[_auditor].score -= _value;
        
    }
    
   
    function reject()
        public
        checkAuditor(msg.sender)
    {
        require(auditorPool[msg.sender].state == AState.Candidate);
                
        auditorPool[msg.sender].state = AState.Online;
        onlineCounter++;
    }
    

    function reverse()
        public
        checkAuditor(msg.sender)
    {        
        require(auditorPool[msg.sender].state == AState.Candidate);
        
        auditorPool[msg.sender].score -= 10;
        
        if(auditorPool[msg.sender].score <= 0){
            auditorPool[msg.sender].state = AState.Offline;
        }else{
            auditorPool[msg.sender].state = AState.Online;
            onlineCounter++;
        }
    }
    
    // To activate the auditor
    function turnOnline()
        public
        checkAuditor(msg.sender)
    {
        require(auditorPool[msg.sender].state == AState.Offline);
        
        require( auditorPool[msg.sender].score > 0 );
        
        auditorPool[msg.sender].state = AState.Online;
        onlineCounter++;
    }
    
    //to deactivate the auditor
    function turnOffline()
        public
        checkAuditor(msg.sender)
    {
        require(auditorPool[msg.sender].state == AState.Online);
        
        auditorPool[msg.sender].state = AState.Offline;
        onlineCounter--;
    }
    
    
}


