pragma solidity >=0.4.22 <0.7.0;


// Import the interface of Auditor Pool Contract
import "./CREDITAuditorPoolSC.sol";


// The Network Service SLA between the MNO and the user.  

contract NetworkSLA {
 
    enum State { Fresh, Init, Active, Violated, Completed }
    State public SLAState;
    
    AuditorPool public ap;
    
    //ServiceAttributes
    string public networkServiceDetail = "";
    uint8 public BlkNeeded = 2;
    uint public CompensationFee = 500 finney; 
    uint public ServiceFee = 1 ether;
    uint public ServiceDuration = 10 minutes;  
    uint public ServiceEnd = 0;
    
    uint public AuditorFeeNoViolation = 10 finney;  
    uint AuditorFeeViolation = 10*AuditorFeeNoViolation;   
    uint VoteFee = AuditorFeeNoViolation;   
    
    uint public AuditorNumber = 3;   //N
    uint public ConfirmNumRequired = 2;   //M: 
    uint SharedFee = (AuditorNumber * AuditorFeeViolation)/2;  
    uint ReportTimeBegin = 0;
    uint ConfirmRepCount = 0;
    
    uint AcceptTimeWin = 2 minutes;   
    uint AcceptTimeEnd = 0;

    address public User;
    uint UserCredit = 0;
    uint CPrepayment = ServiceFee + SharedFee;
    
    address public MNO;
    uint MNOCredit = 0;
    uint PPrepayment = SharedFee;
   
    uint SharedCredit = 0;
    
    address [] public auditorCommittee;

    struct AuditorAccount {
        bool selected;  
        bool violated;   
        uint credit;    
    }
    mapping(address => AuditorAccount) auditors;
    
    event SLAStateModified(address indexed _who, uint _time, State _newstate);
    event SLAViolationRep(address indexed _witness, uint _time, uint _roundID);
    
    
          constructor (AuditorPool _auditorPool, address _MNO, address _user)

        public
    {
        MNO = _MNO;
        User = _user;
        ap = _auditorPool;
    }
        
    
    modifier checkState(State _state){
        require(SLAState == _state);
        _;
    }
    
    modifier checkMNO() {
        require(msg.sender == MNO);
        _;
    }
    
    modifier checkUser() {
        require(msg.sender == User);
        _;
    }
    
    modifier checkMoney(uint _money) {
        require(msg.value == _money);
        _;
    }
    
    modifier checkAuditor() {
        
        require(auditors[msg.sender].selected);
        _;
    }
    
    
    modifier checkTimeOut(uint _endTime) {
        require(now > _endTime);
        _;
    }
    
    modifier checkAllCredit(){
        require(UserCredit == 0);
        
        for(uint i = 0 ; i < auditorCommittee.length ; i++)
            require(auditors[auditorCommittee[i]].credit == 0);
        
        _;
    }
    
    //Set Service Attributes

    function setBlkNeeded(uint8 _blkNeed)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        require(_blkNeed > 1);
        BlkNeeded = _blkNeed;
    }
    
    function setCompensationFee(uint _compensationFee)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        require(_compensationFee > 0);
        uint oneUnit = 1 szabo;
        CompensationFee = _compensationFee*oneUnit;
    }
    
    function setServiceFee(uint _serviceFee)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        require(_serviceFee > 0);
        uint oneUnit = 1 szabo;
        ServiceFee = _serviceFee*oneUnit;
    }
    
    function setAuditorFee(uint _auditorFee)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        require(_auditorFee > 0);
        uint oneUnit = 1 szabo;
        AuditorFeeNoViolation = _auditorFee*oneUnit;
        VoteFee = AuditorFeeNoViolation;
    }
    
    function setServiceDuration(uint _serviceDuration)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        require(_serviceDuration > 0);
        uint oneUnit = 1 minutes;
        ServiceDuration = _serviceDuration*oneUnit;
    }
    
    function setAuditorCommNum(uint _auditorCommNum)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        require(_auditorCommNum > 2);
        require(_auditorCommNum > auditorCommittee.length);
        AuditorNumber = _auditorCommNum;
    }
    
    function setConfirmNum(uint _confirmNum)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        require(_confirmNum > (AuditorNumber/2));
        require(_confirmNum < AuditorNumber);
        
        ConfirmNumRequired = _confirmNum;
    }
    
    function setUser(address _user)
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        User = _user;
    }
    
    // Publish network service details
    function publishService(string _serviceDetail) 
        public 
        checkState(State.Fresh) 
        checkMNO
    {
        networkServiceDetail = _serviceDetail;
    }
    

    function setupSLA() 
        public 
        payable 
        checkState(State.Fresh) 
        checkMNO
        checkMoney(PPrepayment)
    {
       require(AuditorNumber == auditorCommittee.length);
        
        MNOCredit += msg.value;
        SLAState = State.Init;
        AcceptTimeEnd = now + AcceptTimeWin;
        emit SLAStateModified(msg.sender, now, State.Init);
    }
    
    function cancleSLA()
        public
        checkState(State.Init)
        checkMNO
        checkTimeOut(AcceptTimeEnd)
    {
        if(MNOCredit > 0){
            msg.sender.transfer(MNOCredit);
            MNOCredit = 0;
        }
        
        SLAState = State.Fresh;
        
    }
    
    function acceptSLA() 
        public 
        payable 
        checkState(State.Init) 
        checkUser
        checkMoney(CPrepayment)
    {
        require(AuditorNumber == auditorCommittee.length);
        
        UserCredit  += msg.value;
        SLAState = State.Active;
        emit SLAStateModified(msg.sender, now, State.Active);
        ServiceEnd = now + ServiceDuration;
        
        MNOCredit  += ServiceFee;
        UserCredit -= ServiceFee;
        
        MNOCredit -= SharedFee;
        UserCredit-= SharedFee;
        SharedCredit+= SharedFee*2;
    }
    
    
    function resetAuditor() 
        public 
        checkState(State.Active) 
        checkUser
    {
        
        for(uint i = 0 ; i < auditorCommittee.length ; i++){
            if(auditors[auditorCommittee[i]].violated == true){
                auditors[auditorCommittee[i]].violated = false;
                SharedCredit += auditors[auditorCommittee[i]].credit;   
                auditors[auditorCommittee[i]].credit = 0;
                ap.scoreDecrease(auditorCommittee[i], 1);  
            }
        }
        
        ConfirmRepCount = 0;
        ReportTimeBegin = 0;
        
    }
    
    // Reporting the Network Service Violation by the Auditor Interface
    function reportViolation()
        public
        payable
        checkAuditor
        checkMoney(VoteFee)
    {
        
        require( SLAState == State.Violated || SLAState == State.Active );
        
        require(!auditors[msg.sender].violated);
        
        auditors[msg.sender].violated = true;
        auditors[msg.sender].credit += VoteFee;
        
        ConfirmRepCount++;
        
        if( ConfirmRepCount >= ConfirmNumRequired ){
            SLAState = State.Violated;
            emit SLAStateModified(msg.sender, now, State.Violated);
        }
        
        emit SLAViolationRep(msg.sender, now, ServiceEnd);
    }
    
     // Case of Violation of Network Service
    function userEndVSLAandWithdraw()
        public
        checkState(State.Violated) 
        checkUser
    {
        ServiceEnd = now;
         
        for(uint i = 0 ; i < auditorCommittee.length ; i++){
            if(auditors[auditorCommittee[i]].violated == true){
                auditors[auditorCommittee[i]].credit += AuditorFeeViolation; 
                SharedCredit -= AuditorFeeViolation;
            }else{
                ap.scoreDecrease(auditorCommittee[i], 1);  
        
            }
        }
        
        UserCredit += CompensationFee;
        MNOCredit -= CompensationFee;
        
        if(SharedCredit > 0){
            UserCredit += (SharedCredit/2);
            MNOCredit += (SharedCredit/2);
        }
        SharedCredit = 0;
        
        
        SLAState = State.Completed;
        emit SLAStateModified(msg.sender, now, State.Completed);
        
        if(UserCredit > 0){
            msg.sender.transfer(UserCredit);
            UserCredit= 0;
        }
        
    }
    
    function userWithdraw()
        public
        checkState(State.Completed)
        checkTimeOut(ServiceEnd)
        checkUser
    {
        require(UserCredit > 0);
        
        msg.sender.transfer(UserCredit);
            
        UserCredit = 0;
    }
    
    function MNOWithdraw()
        public
        checkState(State.Completed)
        checkTimeOut(ServiceEnd)
        checkMNO
    {
        require(MNOCredit > 0);
        
        msg.sender.transfer(MNOCredit);
        
        MNOCredit = 0;
    }
    
    function auditorWithdraw()
        public
        checkState(State.Completed)
        checkTimeOut(ServiceEnd)
        checkAuditor
    {
        require(auditors[msg.sender].credit > 0);
            
        msg.sender.transfer(auditors[msg.sender].credit);
        
        auditors[msg.sender].credit = 0;
        
        
    }
    
    // Case of No Violation of Network Service
    function MNOEndNSLAandWithdraw()
        public
        checkState(State.Active)
        checkTimeOut(ServiceEnd)
        checkMNO
    {
        for(uint i = 0 ; i < auditorCommittee.length ; i++){
            if(auditors[auditorCommittee[i]].violated == true){
                SharedCredit += auditors[auditorCommittee[i]].credit;   
                auditors[auditorCommittee[i]].credit = 0;
                ap.scoreDecrease(auditorCommittee[i], 1);  
            }else{
                auditors[auditorCommittee[i]].credit += AuditorFeeNoViolation;      
                SharedCredit -= AuditorFeeNoViolation;
            }
            
        }
        
        if(SharedCredit> 0){
            UserCredit += (SharedCredit/2);
            MNOCredit += (SharedCredit/2);
        }
        SharedCredit = 0;
        
        SLAState = State.Completed;
        emit SLAStateModified(msg.sender, now, State.Completed);
        
        if(MNOCredit > 0){
            msg.sender.transfer(MNOCredit);
           MNOCredit = 0;
        }
            
        
    }
    
    
    
    // To continue using the Network Services
    function restartSLA()
        public
        payable
        checkState(State.Completed)
        checkTimeOut(ServiceEnd)
        checkMNO
        checkAllCredit
        checkMoney(PPrepayment)
    {
        require(AuditorNumber == auditorCommittee.length);
        
        ConfirmRepCount = 0;
        ReportTimeBegin = 0;
        
        for(uint i = 0 ; i < auditorCommittee.length ; i++){
            if(auditors[auditorCommittee[i]].violated == true)
                auditors[auditorCommittee[i]].violated = false;
        }
        
        
        MNOCredit = msg.value;
        SLAState = State.Init;
        AcceptTimeEnd = now + AcceptTimeWin;
        emit SLAStateModified(msg.sender, now, State.Init);
    }
    
    function resetSLA()
        public
        checkState(State.Completed)
        checkTimeOut(ServiceEnd)
        checkMNO
        checkAllCredit
    {
        
        ConfirmRepCount = 0;
        ReportTimeBegin = 0;
        
        for(uint i = 0 ; i < auditorCommittee.length ; i++){
            ap.release(auditorCommittee[i]);
            delete auditors[auditorCommittee[i]];
        }
        
        delete auditorCommittee;
        
        SLAState = State.Fresh;
        emit SLAStateModified(msg.sender, now, State.Fresh);
    }

    // call request function from AP SC specifying the blkneeded. 
    function requestACSelection()
        public
        returns
        (bool success)
    {
        require(ap.request(2));
        return true;
    }
    
    
    // call randomized auditor selection function from AP SC.
    //At each time step, randomized auditor selection is called to verify the Network SLA.
    function ACSelectionFromAP(uint _N)
        public
        checkMNO
        returns
        (bool success)
    {
        
        require(ap.randomSelection(_N, MNO, User));
        return true;
    }
    
    function getCommitteeSize()
        public
        view
        returns
        (uint)
    {
        return auditorCommittee.length; 
    }
    
  
    function ReleaseAuditor()
        public
        checkAuditor
    {
        require(SLAState != State.Active);
        require(SLAState != State.Violated);
        
        require( (SLAState == State.Init && now > AcceptTimeEnd) 
                 || SLAState == State.Completed );
        
        
        uint index = auditorCommittee.length;
        for(uint i = 0 ; i<auditorCommittee.length ; i++){
            if(auditorCommittee[i] == msg.sender)
                index = i;
        }
        require(index != auditorCommittee.length);
        auditorCommittee[index] = auditorCommittee[auditorCommittee.length - 1];
            
        auditorCommittee.length--;
            
        delete auditors[msg.sender];
            
        ap.release(msg.sender);
        
    }
}  