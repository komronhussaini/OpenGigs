pragma solidity 0.4.21; 



contract FreelanceGigs {
    
    BehbabTokenInterface public bt; 
    // structures
    struct Gig {
        string gigName;
        string gigDescription;
        uint gigId; 
        uint256 price; 
        address freelancer; 
        address customer;
        bool gigIsCreated; 
        bool gigAccepted; 
        bool gigPaidFor;
        bool freelancerSatisfied; 
        bool customerSatisfied; 
        bool gigIsCompleted;
        bool gigIsCanceled;
    }
    
    struct Freelancer {
        string name; 
        string userDescription;
        string contactInfo;
        uint256 rating;
        bool isFreelancer;
    }
    
    struct Customer {
        string name; 
        string userDescription; 
        string contactInfo;
        uint256 rating; 
        bool isCustomer; 
    }
    
    struct Admin {
        string name;
        bool isAdmin;
    }
    
    adress public creator;
    
    modifier onlyAdmin(){
        require(allAdmins[msg.sender].isAdmin == true || msg.sender == creator);
        _;
    }
    
    // mappings
    mapping (address => Freelancer) private  allFreelancers;
    mapping (address => Customer) private allCustomers; 
    mapping (address => Admin) private allAdmins;
    mapping (uint256 => Gig) private allGigs;
    mapping (uint256 => bool) private gigIsCompleted;
    
    //counter for all created gigs
    uint256 private gigCounter;
    uint256 private completedGigs; 
    uint256 private canceledGigs; 
    
    //events
    event GigIsCreated(uint256 _gigId, string _gigName, string _description); 
    event GigCompleted(uint256 _gigId, uint256 _price, string _gigName);
    event GigCanceled(uint256 _gigId, string _gigName, string _gigDescription);
    event GigIsAccepted(uint256 _gigId, string _gigName, string _freelancerName);
    event GigIsPaidFor(uint256 _gigId, string _gigName, uint256 _gigPrice);
    event CustomerSatisfiedWithGig(uint256 _gigId, string _gigName, string _customerName);
    event freelancerSatisfiedWithGig(uint256 _gigId, string _gigName, string _freelancerName);
    event FreelancerCommended(string _name, address _userAddress, uint256 _rating);
    event CustomerCommended(string _name, address _userAddress, uint256 _rating);
    event RebukeAFreelancer(string _name, address _userAddress, uint256 rating);
    event RebukeACustomer(string _name, address _userAdress, uint256 rating);
    
    //constructor for the contract
    function FreelanceGigs (
        string _adminName,
        address _interfaceAddress
        ) public {
        creator = msg.sender; 
        gigCounter = 0;
        Admin memory a; 
        a.isAdmin = true; 
        a.name = _adminName;
        allAdmins[msg.sender] = a;
        bt = BehbabTokenInterface(_interfaceAddress);
    }
    
    // allows contract to hold ethereum
    function()public payable{}
    
    // admin functions
    function addAdmin(
        address _newAdminAddress
        ) onlyAdmin {
        allAdmins[_newAdminAddress].isAdmin = true;
    }
    
    function withdraw(uint256 _value) onlyAdmin {
        address(this).transfer(_value);
    }
    
    function deposit(uint256 _value) onlyAdmin {
        msg.sender.transfer(_value); 
    }
    
    function deleteContract() onlyAdmin {
        selfdestruct(1); 
    }
    
    // makes the user a freelancer
    function becomeAFreelancer(
        string _name, 
        string _description,
        string _contactInfo
        ) public {
        Freelancer memory f; 
        f.name = _name; 
        f.userDescription = _description;
        f.contactInfo = _contactInfo;
        f.isFreelancer = true;
        f.rating++;
        allFreelancers[msg.sender] = f;
        bt.transfer(address(this), 1); 
    }
    
    // makes the user a customer
    function becomeACustomer(
        string _name, 
        string _description,
        string _contactInfo
        ) public {
        Customer memory c;
        c.name = _name;
        c.userDescription = _description;
        c.contactInfo = _contactInfo;
        c.isCustomer = true;
        c.rating++;
        allCustomers[msg.sender] = c; 
        bt.transfer(address(this), 1); 
    }
    
    // creates a new gig
    function createAGig(
        string _gigName, 
        string _gigDescription,
        uint256 _price
        ) public {
        //checks is user is a customer
        require(allCustomers[msg.sender].isCustomer == true); 
        // assigns attributes to the gig
        Gig memory g;
        g.gigName = _gigName; 
        g.gigDescription = _gigDescription;
        g.price = _price;
        g.customer = msg.sender;
        g.gigIsCreated = true;
        g.gigId = gigCounter;
        allGigs[gigCounter] = g;
        gigCounter++;
        emit GigIsCreated(g.gigId, g.gigName, g.gigDescription);
    }
    
    //freelancer accpepts the gig
    function acceptGig(uint256 _gigId) public {
        require(allFreelancers[msg.sender].isFreelancer == true);
        Gig memory g = allGigs[_gigId];
        require(g.gigAccepted == false);
        g.freelancer = msg.sender;
        g.gigAccepted = true;
        allGigs[_gigId] = g; 
        emit GigIsAccepted(_gigId, g.gigName, allFreelancers[msg.sender].name);
    }
    
    //customer pays for the gig
    function payForGig(
        uint256 _gigId
        ) public payable{
        require(allGigs[_gigId].customer == msg.sender);
        address(this).transfer(allGigs[_gigId].price);
        emit GigIsPaidFor(_gigId, allGigs[_gigId].gigName, allGigs[_gigId].price);
    }
    
    function customerIsSatisfiedWithGig(
        uint256 _gigId
        ) public {
        //checks if user is a valid customer
        require(allCustomers[msg.sender].isCustomer == true);
        require(allGigs[_gigId].customer == msg.sender);
        // marks the gig as customer satisfied
        allGigs[_gigId].customerSatisfied = true;
        completeGig(_gigId);
        emit CustomerSatisfiedWithGig(_gigId, allGigs[_gigId].gigName, allCustomers[msg.sender].name);
    }
    
    function freelancerIsSatisfiedWithGig(
        uint256 _gigId
        ) public {
        //checks if user is a valid freelancer
        require(allGigs[_gigId].freelancer == msg.sender);
        // marks the gig as freelancer satisfied
        allGigs[_gigId].freelancerSatisfied = true;
        completeGig(_gigId);
        emit freelancerSatisfiedWithGig(_gigId, allGigs[_gigId].gigName, allFreelancers[msg.sender].name);
    }
    
    function cancelGig(
        uint256 _gigId
        ) public {
        Gig memory g = allGigs[_gigId]; 
        require(msg.sender == g.customer || g.freelancer == msg.sender);
        require(g.gigIsCompleted == false);
        require(g.gigIsCreated == true); 
        g.customer.transfer(g.price);
        allGigs[_gigId].gigIsCanceled = true;
        canceledGigs++;
        emit GigCanceled(g.gigId, g.gigName, g.gigDescription);
    }
    
    function commendFreelancer(
        uint256 _gigId
        ) public {
        Gig memory g = allGigs[_gigId];
        require(g.customer == msg.sender);
        require(g.gigIsCompleted == true || g.gigIsCanceled == true);
        allFreelancers[g.freelancer].rating++;
        emit FreelancerCommended(allFreelancers[g.freelancer].name, g.freelancer, allFreelancers[g.freelancer].rating);
    }
    
    function commendCustomer(
        uint256 _gigId
        ) public {
        Gig memory g = allGigs[_gigId];
        require(g.freelancer == msg.sender);
        require(g.gigIsCompleted == true || g.gigIsCanceled == true);
        allCustomers[g.customer].rating++;
        emit CustomerCommended(allCustomers[g.customer].name, g.customer, allCustomers[g.customer].rating);
    }
    
    function rebukeFreelancer(
        uint256 _gigId
        ) public {
        Gig memory g = allGigs[_gigId];
        require(g.customer == msg.sender);
        require(g.gigIsCompleted == true || g.gigIsCanceled == true);
        allFreelancers[g.freelancer].rating--;
        emit RebukeAFreelancer(allFreelancers[g.freelancer].name, g.freelancer, allFreelancers[g.freelancer].rating);
    }
    
    function rebukeCustomer(
        uint256 _gigId
        ) public {
        Gig memory g = allGigs[_gigId]; 
        require(g.freelancer == msg.sender);
        require(g.gigIsCompleted == true || g.gigIsCanceled == true);
        allCustomers[g.customer].rating--;
        emit RebukeACustomer(allCustomers[g.customer].name, g.customer, allCustomers[g.customer].rating);
    }
    
    // getters for gig info
    function getGigTitle(
            uint256 _gigId
        ) public constant returns (string) {
        return allGigs[_gigId].gigName; 
    }
    
    function getGigDesscription(
            uint256 _gigId
        )public constant returns (string) {
        return allGigs[_gigId].gigName;    
    }
    
    function getGigPrice(
            uint256 _gigId
        ) public constant returns (uint256) {
        return allGigs[_gigId].price;    
    }
    
    function getGigCustomer(
            uint256 _gigId
        ) public constant returns (address) {
        return allGigs[_gigId].customer;
    }
    
    function getGigFreelancer(
            uint256 _gigId
        ) public constant returns (address){
        return allGigs[_gigId].freelancer;
    }
    
    function getGigAccepted(
            uint256 _gigId
        ) public constant returns (bool){
        return allGigs[_gigId].gigAccepted;
    }
    
    function getGigPaidFor(
            uint256 _gigId
        ) public constant returns (bool){
        return allGigs[_gigId].gigPaidFor;
    }
    
    function getGigFreelancerSatisfied(
            uint256 _gigId
        ) public constant returns (bool){
        return allGigs[_gigId].freelancerSatisfied;
    }
    
    function getCustomerSatisfied(
        uint256 _gigId
        ) public constant returns (bool){
        return allGigs[_gigId].customerSatisfied;
    }
    
    function getGigIsCancelled(
        uint256 _gigId
        ) public constant returns (bool){
        return allGigs[_gigId].gigIsCanceled;
    }
    
    function getGigIsCompleted(
        uint256 _gigId
        ) public constant returns (bool){
        return allGigs[_gigId].gigIsCompleted;
    }
    
    //freelancer getters
    function getFreelancerName(
            address _freelancerAddress
        ) public constant returns (string) {
        return allFreelancers[_freelancerAddress].name;
    }
    
    function getFreelancerDescription(
            address _freelancerAddress
        ) public constant returns (string){
        return allFreelancers[_freelancerAddress].userDescription;
    }
    
    function getFreelancerRating(
            address _freelancerAddress
        ) public constant returns (uint256){
        return allFreelancers[_freelancerAddress].rating; 
    }
    
    //customer getters
    function getCustomerName(
        address _customerAddress
        ) public constant returns (string){
        return allCustomers[_customerAddress].name; 
    }
    
    function getCustomerDescription(
        address _customerAddress
        ) public constant returns(string){
        return allCustomers[_customerAddress].userDescription;
    }
    
    function getCustomerRating(
        address _customerAddress
        ) public constant returns(uint256) {
            return allCustomers[_customerAddress].rating;
        }
    
    // general getters
    function getGigCount()public constant returns(uint256){
        return gigCounter;
    }
    
    function getCompletedGigs()public constant returns(uint256) {
        return completedGigs;
    }
    function getCanceledGigs() public constant returns(uint256) {
        return canceledGigs;
    }

    function completeGig(
            uint256 _gigId
    ) internal {
        Gig memory g = allGigs[_gigId];
        require(g.customerSatisfied == true);
        require(g.freelancerSatisfied == true);
        g.freelancer.transfer(g.price);
        completedGigs++;
        emit GigCompleted(_gigId, g.price, g.gigName);
    }
}

contract BehbabTokenInterface{
    function transfer(address _to, uint256 _value);
    function transferFrom(address _from, address _to, uint256 _value) returns(bool);
}