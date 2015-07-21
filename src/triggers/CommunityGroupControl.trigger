trigger CommunityGroupControl on Community_Group_Control__c (before insert, after insert, after update) {

	if (Trigger.isBefore && Trigger.isInsert) {
		Boolean validationPassed = true;
		Map<Id, CollaborationGroup> newChatterGroupsByGCid = new Map<Id, CollaborationGroup>();
		Map<String, Community_Group_Control__c> checkUniqueNamesMap = new Map<String, Community_Group_Control__c>();
		Map<String, Id> communityIdByName = new Map<String, Id>();
		Boolean firstCommunity = true;
		for (Network nItem : [SELECT Id, Name FROM Network LIMIT 100]) {
			communityIdByName.put(nItem.Name, nItem.Id);
			if (firstCommunity) {
				communityIdByName.put('Community', nItem.Id);
				firstCommunity = false;
			}
		}
		for (Community_Group_Control__c cgcItem : Trigger.new) {
			// Validation block
			if (checkUniqueNamesMap.containsKey(cgcItem.Name)) {
				cgcItem.addError(Label.ERR_Dup_Group_Name);
				validationPassed = false;
			}
			else {
				checkUniqueNamesMap.put(cgcItem.Name, cgcItem);
			}
			// Operation block
			if (validationPassed && cgcItem.Chatter_Group_ID__c == NULL) {
				newChatterGroupsByGCid.put(cgcItem.Id, new CollaborationGroup(
					CollaborationType = cgcItem.Type__c,
					Description = cgcItem.Description__c,
					IsArchived = false,
					Name = cgcItem.Name,
					NetworkId = Network.getNetworkId()
				));
			}
		}
		// Check for duplicated Group Name
		if (validationPassed) {
			for (Community_Group_Control__c cgcItem2 : [SELECT Name FROM Community_Group_Control__c WHERE Name IN :checkUniqueNamesMap.keySet()]) {
				checkUniqueNamesMap.get(cgcItem2.Name).addError(Label.ERR_Dup_Group_Name);
				validationPassed = false;
			}
		}
		// Create CollaborationGroup and populate Chatter_Group_ID__c field
		if (validationPassed && newChatterGroupsByGCid.size() > 0) {
			insert newChatterGroupsByGCid.values();
			for (Community_Group_Control__c cgcItem3 : Trigger.new) {
				if (cgcItem3.Chatter_Group_ID__c == NULL ) {
					cgcItem3.Chatter_Group_ID__c = newChatterGroupsByGCid.get(cgcItem3.Id).Id;
				}
			}
		}
	}

	if (Trigger.isAfter && Trigger.isInsert) {
		Map<Id, Community_Group_Control__c> GroupControlIdByChatterGroupId = new Map<Id, Community_Group_Control__c>();
		for (Community_Group_Control__c cgcItem : Trigger.new) {
			if (cgcItem.Chatter_Group_ID__c != NULL) {
				GroupControlIdByChatterGroupId.put(Id.valueOf(cgcItem.Chatter_Group_ID__c), cgcItem);
			}
		}
		if (GroupControlIdByChatterGroupId.size() > 0) {
			List<Community_Group_Manager__c> membersCommunityGroup = new List<Community_Group_Manager__c>();
			for (CollaborationGroupMember cgmItem : [
						SELECT MemberId, CollaborationGroupId
						FROM CollaborationGroupMember
						WHERE CollaborationGroupId IN :GroupControlIdByChatterGroupId.keySet()]
							) {
				Community_Group_Control__c cgcFromMap = GroupControlIdByChatterGroupId.get(cgmItem.CollaborationGroupId);
				membersCommunityGroup.add(
					new Community_Group_Manager__c(
						Group_Control__c = cgcFromMap.Id,
						Group_Manager_User__c = cgmItem.MemberId,
						Manager_Role__c = (cgcFromMap.OwnerId == cgmItem.MemberId ? 'Owner' : 'Manager')
					)
				);
			}
			if (membersCommunityGroup.size() > 0) {
				insert membersCommunityGroup;
			}
		}
	}

	if (Trigger.isAfter && Trigger.isUpdate) {
		Boolean validationPassed2 = true;
		Map<String, Community_Group_Control__c> checkUniqueNamesMap2 = new Map<String, Community_Group_Control__c>();
		Map<String,String> changedCollaborationType = new Map<String,String>();
		Set<Id> excludeCurrentGroupControls = new Set<Id>();

		// change owner collections
		Map<Id,Id> chatterGroupsWithNewOwners = new Map<Id,Id>();
		Map<Id,Id> groupControlsWithNewOwners = new Map<Id,Id>();
		List<Community_Group_Control__c> groupControlsList = new List<Community_Group_Control__c>();

		// change name in chatter group collection
		Map<Id, String> chatterGroupToNewNameMap = new Map<Id, String>();

		for (Community_Group_Control__c cgcItem2 : Trigger.new) {
			if (cgcItem2.Name != Trigger.oldMap.get(cgcItem2.Id).Name) {
				if (checkUniqueNamesMap2.containsKey(cgcItem2.Name)) {
					cgcItem2.addError(Label.ERR_Dup_Group_Name);
					validationPassed2 = false;
				}
				checkUniqueNamesMap2.put(cgcItem2.Name, cgcItem2);
				excludeCurrentGroupControls.add(cgcItem2.Id);
				if (cgcItem2.Chatter_Group_ID__c != NULL) {
					chatterGroupToNewNameMap.put(cgcItem2.Chatter_Group_ID__c, cgcItem2.Name);
				}
			}

			// Change owner block
			if (cgcItem2.Type__c != Trigger.oldMap.get(cgcItem2.Id).Type__c && cgcItem2.Chatter_Group_ID__c != NULL) {
				changedCollaborationType.put(cgcItem2.Chatter_Group_ID__c, cgcItem2.Type__c);
			}
			if (cgcItem2.OwnerId != Trigger.oldMap.get(cgcItem2.Id).OwnerId) {
				groupControlsList.add(cgcItem2);
				groupControlsWithNewOwners.put(cgcItem2.Id, cgcItem2.OwnerId);
				if (cgcItem2.Chatter_Group_ID__c != NULL) {
					Id tId = Id.valueOf(cgcItem2.Chatter_Group_ID__c);
					chatterGroupsWithNewOwners.put(tId, cgcItem2.OwnerId);
				}
			}

		}
		if (validationPassed2 && checkUniqueNamesMap2.size() > 0) {
			for (Community_Group_Control__c cgcItem3 : [SELECT Name FROM Community_Group_Control__c WHERE Name IN :checkUniqueNamesMap2.keySet() AND Id NOT IN :excludeCurrentGroupControls]) {
				checkUniqueNamesMap2.get(cgcItem3.Name).addError(Label.ERR_Dup_Group_Name);
				validationPassed2 = false;
			}
		}
		if (validationPassed2 && chatterGroupToNewNameMap.size() > 0) {
			List<CollaborationGroup> changeNameList = [SELECT Id, Name FROM CollaborationGroup WHERE Id IN :chatterGroupToNewNameMap.keySet()];
			for (CollaborationGroup cgItem : changeNameList) {
				cgItem.Name = chatterGroupToNewNameMap.get(cgItem.Id);
			}
			update changeNameList;
		}
		if (validationPassed2 && changedCollaborationType.size() > 0) {
			List<CollaborationGroup> cgList = [SELECT Id, CollaborationType FROM CollaborationGroup WHERE Id IN :changedCollaborationType.keySet()];
			for (CollaborationGroup cgItem : cgList) {
				cgItem.CollaborationType = changedCollaborationType.get(cgItem.Id);
			}
			update cgList;
		}

		// Change owner block
		if (validationPassed2 && groupControlsWithNewOwners.size() > 0) {
			Set<Id> newLuckyOnes = new Set<Id>();
			newLuckyOnes.addAll(groupControlsWithNewOwners.values());
			Set<String> groupManagersUniqueId = new Set<String>();
			List<Community_Group_Manager__c> cgmListToUpsert = new List<Community_Group_Manager__c>();
			for (Community_Group_Manager__c cgmItem : [
								SELECT Id, Group_Manager_User__c, Group_Control__c, Manager_Role__c FROM Community_Group_Manager__c
								WHERE (Group_Manager_User__c IN :newLuckyOnes OR Manager_Role__c = 'Owner')
									AND Group_Control__c IN :groupControlsWithNewOwners.keySet()]) {
				Id currentNewGroupOwnerId = groupControlsWithNewOwners.get(cgmItem.Group_Control__c);
				if (cgmItem.Group_Manager_User__c != currentNewGroupOwnerId && cgmItem.Manager_Role__c == 'Owner') {
					cgmItem.Manager_Role__c = 'Manager';
					cgmListToUpsert.add(cgmItem);
				}
				if (cgmItem.Group_Manager_User__c == currentNewGroupOwnerId && cgmItem.Manager_Role__c != 'Owner') {
					cgmItem.Manager_Role__c = 'Owner';
					cgmListToUpsert.add(cgmItem);
				}
				groupManagersUniqueId.add('' + cgmItem.Group_Control__c + cgmItem.Group_Manager_User__c);
			}

			Set<String> groupSubscriptionUniqueId = new Set<String>();
			for (EntitySubscription esItem : [
								SELECT ParentId, SubscriberId FROM EntitySubscription
								WHERE SubscriberId IN :newLuckyOnes AND ParentId IN :groupControlsWithNewOwners.keySet()]) {
				groupSubscriptionUniqueId.add('' + esItem.ParentId + esItem.SubscriberId);
			}

			Set<String> existingChatterGroupManagers = new Set<String>();
			Map<String,CollaborationGroupMember> chatterMemberUniqueIdMap = new Map<String,CollaborationGroupMember>();
			if (chatterGroupsWithNewOwners.size() > 0) {
				for (CollaborationGroupMember cgmItem2 : [
								SELECT Id, MemberId, CollaborationGroupId, CollaborationRole FROM CollaborationGroupMember
								WHERE MemberId IN :newLuckyOnes AND CollaborationGroupId IN :chatterGroupsWithNewOwners.keySet()]) {
					chatterMemberUniqueIdMap.put('' + cgmItem2.CollaborationGroupId + cgmItem2.MemberId, cgmItem2);
				}
			}

			List<EntitySubscription> subscriptionsListToInsert = new List<EntitySubscription>();
			List<CollaborationGroupMember> chatterMembersToUpsert = new List<CollaborationGroupMember>();
			for (Community_Group_Control__c cgcItem : groupControlsList) {
				if (!groupManagersUniqueId.contains('' + cgcItem.Id + cgcItem.OwnerId)) {
					cgmListToUpsert.add(new Community_Group_Manager__c(
						Group_Manager_User__c = cgcItem.OwnerId,
						Group_Control__c = cgcItem.Id,
						Manager_Role__c = 'Owner'
					));
				}
				if (!groupSubscriptionUniqueId.contains('' + cgcItem.Id + cgcItem.OwnerId)) {
					subscriptionsListToInsert.add(new EntitySubscription(
						SubscriberId = cgcItem.OwnerId,
						ParentId = cgcItem.Id
					));
				}
				CollaborationGroupMember tCgm = chatterMemberUniqueIdMap.get('' + cgcItem.Chatter_Group_ID__c + cgcItem.OwnerId);
				if (tCgm == NULL) {
					chatterMembersToUpsert.add(new CollaborationGroupMember(
						MemberId = cgcItem.OwnerId,
						CollaborationGroupId = cgcItem.Chatter_Group_ID__c,
						CollaborationRole = 'Admin'
					));
				}
				else if (tCgm.CollaborationRole != 'Admin') {
					tCgm.CollaborationRole = 'Admin';
					chatterMembersToUpsert.add(tCgm);
				}
			}

			if (chatterMembersToUpsert.size() > 0) {
				upsert chatterMembersToUpsert;
			}
			if (cgmListToUpsert.size() > 0) {
				upsert cgmListToUpsert;
			}
			try {
				if (subscriptionsListToInsert.size() > 0) {
					insert subscriptionsListToInsert;
				}
			}
			catch (Exception e) {}

			if (chatterGroupsWithNewOwners.size() > 0) {
				List<CollaborationGroup> updateOwnerList = [SELECT Id, OwnerId FROM CollaborationGroup WHERE Id IN :chatterGroupsWithNewOwners.keySet()];
				for (CollaborationGroup cgItem : updateOwnerList) {
					cgItem.OwnerId = chatterGroupsWithNewOwners.get(cgItem.Id);
				}
				update updateOwnerList;
			}
		}
	}
}