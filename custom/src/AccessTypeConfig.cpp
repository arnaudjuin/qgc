#include "AccessTypeConfig.h"
#include "AccessType.h"
#include <iostream>

//AccessType CURRENT_USER_ACCESS_TYPE = Basic;
//AccessType CURRENT_USER_ACCESS_TYPE = Expert;
AccessType CURRENT_USER_ACCESS_TYPE = Factory;

AccessType getInitialUserAccessType() {
    std::cout << "THIS IS A TEST" << std::endl;
    return CURRENT_USER_ACCESS_TYPE;
}

void setUserAccessType(AccessType newAccessType) {
    CURRENT_USER_ACCESS_TYPE = newAccessType;
    std::cout << "SET CURRENT_USER_ACCESS_TYPE TO: " << CURRENT_USER_ACCESS_TYPE << std::endl;
}
