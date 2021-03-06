/* 
 * Unity - Communities
 * 
 * Community is critical to the student experience--but building community is 
 * just plain hard. Built on Communities and designed specifically for higher ed, 
 * Unity is a powerful networking tool to help you generate engagement and 
 * connect your campus.
 * 
 * Copyright (C) 2015 Motivis Learning Systems Inc.
 * 
 * This program is free software: you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 * 
 * To contact Motivis Learning Systems Inc.
 * 25 Pelham Road
 * Salem, NH 03790
 * unity@motivislearning.com
 */

@isTest
private class CommunityTest3 {
/*Triggers Tests*/

	static testMethod void test_CommunityNewsTrigger() {
		insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now(),Expiration_Date__c=Datetime.now().addDays(1),
			Alert__c=true);
		try {
			insert new Community_News__c(Title__c='t',Teaser__c='t',Entry_Date__c=Datetime.now().addDays(-1),Expiration_Date__c=Datetime.now().addDays(2),
				Alert__c=true);
		}
		catch(Exception e) {}
		System.assert( [SELECT Id,Name FROM Community_News__c WHERE Title__c='t'  LIMIT 10].size()>0 );
		
	}

	static testMethod void test_CommunityGroupControlTrigger() {
		insert new Community_Group_Control__c(Name='t',Discoverable__c=true,Type__c='Public',Network__c='Internal');
		try {
			insert new Community_Group_Control__c(Name='t',Discoverable__c=true,Type__c='Public',Network__c='Internal');
		}
		catch(Exception e) {}
		try {
			insert new List<Community_Group_Control__c> {
				new Community_Group_Control__c(Name='t1',Discoverable__c=true,Type__c='Public',Network__c='Internal'),
				new Community_Group_Control__c(Name='t1',Discoverable__c=true,Type__c='Public',Network__c='Internal')
			};
		}
		catch(Exception e) {}
		System.assert( [SELECT Id,Name FROM Community_Group_Control__c LIMIT 10].size()>0 );
	}

	static testMethod void test_CommunityAdminTrigger() {
		insert new Community_Registration__c(SetupOwnerId = UserInfo.getOrganizationId());
		List<Community_Admins__c> insertList = new List<Community_Admins__c>();
		insertList.add(new Community_Admins__c(Terms_Body__c = 'TestTerms1', Terms_Req_New_Signature__c = TRUE, Terms_Status__c = 'Archived'));
		insertList.add(new Community_Admins__c(Terms_Body__c = 'TestTerms1', Terms_Req_New_Signature__c = TRUE, Terms_Status__c = 'Published'));
		insert insertList;

		List<Community_Admins__c> comAd = [SELECT Terms_Body__c, Terms_Req_New_Signature__c, Terms_Status__c FROM Community_Admins__c LIMIT 1];
		System.assert( comAd.size()>0 ); 
		comAd[0].Terms_Body__c = 'TestTerms2';
		comAd[0].Terms_Status__c = 'Published';
		
		update comAd[0];
	}

	static testMethod void test_UserTrigger() {		
      	UserRole ur = [Select Id, Name From UserRole where Name = 'CEO'];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(alias='alias', email='email@email.com', emailencodingkey='UTF-8', lastname='lastname', firstname = 'firstName', languagelocalekey='en_US',
            localesidkey='en_US', profileid = profile.Id, timezonesidkey='America/Los_Angeles', username='ttsde.tedf2@testmail.com',
            FederationIdentifier='TestContactName.TestContactLastname2', UserRoleId = ur.Id);
        insert u;
       System.runAs(u){
       		Account acc = new Account(Name='testAccount');
	        insert acc;
	        Contact con = new Contact(LastName='TCLN', MailingPostalCode='99013', email='testc@testdomain.com', AccountId=acc.Id, Primary_Role__c='Student');
	        insert con;
	        Profile p = [select Id, Name from Profile where Name = 'Customer Community User']; 
			User newUser = new User(
			profileId = p.id,
			username = 'newUser@yahoo.com',
			email = 'pb@ff.com',
			emailencodingkey = 'UTF-8',
			localesidkey = 'en_US',
			languagelocalekey = 'en_US',
			timezonesidkey = 'America/Los_Angeles',
			alias='nuser',
			lastname='lastname',
			contactId = con.id
			);
			insert newUser;
			System.assert( [SELECT Id,Name FROM USER WHERE username = 'newUser@yahoo.com' LIMIT 10].size()>0 );
       }
    }

    static testMethod void test_CommunityResourceTrigger() {
		Community_Theme__c cth = new Community_Theme__c(Name='t',Theme_Type__c='Resource');
		insert cth;
		Community_Tag__c ct = new Community_Tag__c(Name='t',Community_Theme__c=cth.Id);
		insert ct;
		Community_Resource__c cr = new Community_Resource__c(Resource_Name__c = 'TestRes', Primary_Tag__c = ct.id, Quick_Link__c = true, Name = 'testR');
		insert cr;
		Community_Resource__c cr_1 = new Community_Resource__c(Resource_Name__c = 'TestRes1', Primary_Tag__c = ct.id, Help_Link__c = true, Name = 'testR0');
		insert cr_1;
		try{
		Community_Resource__c cr_2 = new Community_Resource__c(Resource_Name__c = 'TestRes10', 
																Primary_Tag__c = ct.id, 
																Link__c = 'www.google.com', 
																Quick_Link__c = true, 
																Help_Link__c = true, 
																Name = 'testR',
																Status__c = 'Active');
		insert cr_2;
		}catch(Exception ex){}
		try{
			Community_Resource__c cr3 = new Community_Resource__c(Resource_Name__c = 'TestRes2');
			insert cr3;
		}catch(Exception ex){}
		try{
			Community_Resource__c cr_4 = new Community_Resource__c(Resource_Name__c = 'TestRes3', Primary_Tag__c = ct.id, Link__c = 'www.google.com', Quick_Link__c = true);
			insert cr_4;
		}catch(Exception ex){}
		System.assert( [SELECT Id,Name FROM Community_Resource__c LIMIT 10].size()>0 );
	}
}
