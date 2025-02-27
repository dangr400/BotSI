/* Initial beliefs and rules */
numAnswer(1).  

// Check if bot answer requires a service
service(Answer, translating):- 			// Translating service
	checkTag("<translate>",Answer).
service(Answer, mailing):- 				// Mailing service
	checkTag("<mail>",Answer).
service(Answer, addingBot):- 			// Adding a bot property service
	checkTag("<botprop>",Answer).
service(Answer, creatingSet):- 			// Creating a set service
	checkTag("<addset>",Answer)&
	not checkTag("<new>",Answer).
service(Answer, addingSet):- 			// Adding a new value to a set service
	checkTag("<addset>",Answer)&
	checkTag("<new>",Answer).
service(Answer, creatingMap):- 			// Creating a map service
	checkTag("<addmap>",Answer) &
	not checkTag("<new>",Answer).
service(Answer, addingMap):- 			// Adding a new property with value to a map service
	checkTag("<addmap>",Answer) &
	checkTag("<new>",Answer).
service(Answer, addingFile):- 			// Adding content to a file service
	checkTag("<addtxt>",Answer).
service(Answer, creatingFile):- 		// Creating a new file service
	checkTag("<file>",Answer) &
	not service(Answer, addingfile).
	
// Checking a concrete service required by the bot ia as simple as find the required tag
// as a substring on the string given by the second parameter
checkTag(Service,String) :-
	.substring(Service,String).


// Gets into Val the first substring contained by a tag Tag into String
getValTag(Tag,String,Val) :- 
	.substring(Tag,String,Fst) &       // First: find the Fst Posicition of the tag string              
	.length(Tag,N) &                   // Second: calculate the length of the tag string
	.delete(0,Tag,RestTag) &     
	.concat("</",RestTag,EndTag) &     // Third: build the terminal of the tag string
	.substring(EndTag,String,End) &    // Four: find the Fst Position of the terminal tag string
	.substring(String,Val,Fst+N,End).  // Five: get the Val tagged 


// Filter the answer to be showed when the service indicated as second arg is done
filter(Answer, translating, [To,Msg]):-
	getValTag("<to>",Answer,To) &
	getValTag("<msg>",Answer,Msg).
	
filter(Answer, mailing, [To,Sub,Msg]):-
	getValTag("<to>",Answer,To) &
	getValTag("<subject>",Answer,Sub) &
	getValTag("<msg>",Answer,Msg).
	
filter(Answer, addingBot, [ToWrite,Route]):-
	getValTag("<name>",Answer,Name) &
	getValTag("<val>",Answer,Val) &
	.concat(Name,":",Val,ToWrite) &
	bot(Bot) &
	.concat("/bots/",Bot,BotName) &
	.concat(BotName,"/config/properties.txt",Route).	

filter(Answer, addingFile, [Text,Route]) :-
	getValTag("<file>",Answer,Name) & // Si solo se da el nombre sin extensión
	.concat(Name,".txt",Route) & 		// Adecuar a la requerida
	getValTag("<txt>", Answer, Text).
	
filter(Answer, addingSet, [Text,Route]):- 
	getValTag("<new>",Answer,Text) &
	.substring("</new>",Answer,Inicio) &
	.length("</new>",N) &
	.substring("</addset>",Answer,Fin) & 
	.substring(Answer,Name,Inicio+N+1,Fin-1)&
	.concat(Name,".txt",File) &
	bot(Bot) &
	.concat("/bots/",Bot,BotName) &
	.concat(BotName,"/sets/",SetsPath) &
	.concat(SetsPath,File,Route).

filter(Answer, addingMap, [Text,Route]):- 
	getValTag("<new>",Answer,Text) &
	.substring("</new>",Answer,Inicio) &
	.length("</new>",N) &
	.substring("</addmap>",Answer,Fin) & 
	.substring(Answer,Name,Inicio+N+1,Fin-1)&
	.concat(Name,".txt",File) &
	bot(Bot) &
	.concat("/bots/",Bot,BotName) &
	.concat(BotName,"/maps/",MapsPath) &
	.concat(MapsPath,File,Route).

filter(Answer, creatingSet, [Route]):- 
	getValTag("<addset>", Answer, Name) &
	.concat(Name, ".txt", File) &
	bot(Bot) &
	.concat("/bots/", Bot, BotName) &
	.concat(BotName, "/sets/", SetsPath) &
	.concat(SetsPath, File, Route).

filter(Answer, creatingMap, [Route]):- 
	getValTag("<addmap>", Answer, Name) &
	.concat(Name, ".txt", File) &
	bot(Bot) &
	.concat("/bots/", Bot, BotName) &
	.concat(BotName, "/maps/", SetsPath) &
	.concat(SetsPath, File, Route).

filter(Answer, creatingFile, [Route]):- 
	getValTag("<file>", Answer, Name) & 
	.concat(Name, ".txt", Route).


/* Initial goals */

!checkingBot.

/* Plans */  

+!checkingBot <-
	!setupTool("Blex",BotId).        
	
+!setupTool(Name, Id): true
	<- 	makeArtifact(Name,"bot.Servicios",[Name],Id);
		.wait(1000);
		focus(Id);
		makeArtifact("guiChat","chat.ChatGUI",[],GUI);
		focus(GUI);
		.wait(200).

+!say(Who,What) : numAnswer(N) <-
	!showQuest(Who,What);
	+pregunta(N,What);
	+interlocutor(Who);
	.wait(3000); 
	chat(What).
	
+!say(Who,What) <- 
	.println("?").
	
+say(What) <-
	println("El Bot Master ha dicho: ", What);
	chatSincrono(What,Answer);
	println("El Bot contesta: ",Answer);
	show(Answer).

+!waitAnswer <-
	.wait(recibida(_));
	.wait(3000);
	.abolish(recibida(_)).

+!showQuest(Who,Question) <-
	.println("----------------------------");
	.println(Who," dice: ",Question);  
	.println("----------------------------");
	.println.

+!showAnsw(Answer) : numAnswer(N) & bot(Bot) & interlocutor(Who)
	<-	.println("---------------------------------------------------");
		.println;
		.println(Bot, " contesta: ", Answer);
		.println;
		.println("---------------------------------------------------");
		.wait(3000);
		+contesta(N,Answer);  
		.send(Who,achieve,say("Blex",Answer));
		-interlocutor(Who);
		-+numAnswer(N+1);
		.wait(3000);
		.println.
		
+!showAnsw(Answer) : numAnswer(N) & bot(Bot) 
	<-	.println("---------------------------------------------------");
		.println;
		.println(Bot, " contesta: ", Answer);
		.println;
		.println("---------------------------------------------------");
		.wait(3000);
		+contesta(N,Answer);
		-+numAnswer(N+1);
		.wait(3000);
		.println.
		
+!doService(translating, Answer, Response): 
		bot(Name) & 
		filter(Answer, translating, [To,Msg])
	<-	translate("es", To, Msg, Translation);
		.concat("La traduccion que pediste es: ", Translation, Response).
+!doService(mailing, Answer, Response):
		bot(Name) & 
		filter(Answer, mailing, [To,Subject,Msg])
	<-	mail(To, Subject, Msg);
		.concat("Ya he enviado el correo que pediste a: ", To, Response).
+!doService(addingBot, Answer, Response):
		bot(Name) & 
		filter(Answer, addingBot, [Text,Route]) 
	<-	writeOnFile(Text,Route);
		.concat("He insertado la nueva propiedad del bot: ", Text, Response).
+!doService(creatingSet, Answer, Response):
		bot(Name) & 
		filter(Answer, creatingSet, [Route]) 
	<-	writeOnFile(Text,Route);
		.concat("He creado el conjunto: ", Route, Response).
+!doService(addingSet, Answer, Response):
		bot(Name) & 
		filter(Answer, addingSet, [Text,Route]) 
	<-	writeOnFile(Text,Route);
		.concat("He insertado el valor: ", Text, ResponseA);
		.concat(" en el conjunto: ", Route, ResponseB);
		.concat(ResponseA, ResponseB, Response).
+!doService(creatingMap, Answer, Response):
		bot(Name) & 
		filter(Answer, creatingMap, [Route]) 
	<-	writeOnFile(Text,Route);
		.concat("He creado el nuevo map: ", Route, Response).
+!doService(addingMap, Answer, Response):
		bot(Name) & 
		filter(Answer, addingMap, [Text,Route]) 
	<-	writeOnFile(Text,Route);
		.concat("He insertado la nueva relacion: ", Text, Response).
+!doService(addingFile, Answer, Response):
		bot(Name) & 
		filter(Answer, addingFile, [Text,Route]) 
	<-	writeOnFile(Text,Route);
		.concat("He insertado el texto: ", Text, ResponseA);
		.concat(" en el fichero: ", Route, ResponseB);
		.concat(ResponseA, ResponseB, Response).
+!doService(creatingFile, Answer, Response):
		bot(Name) & 
		filter(Answer, creatingFile, [Route]) 
	<-	createFile(Text,Route);
		.concat("He creado el fichero: ", Route, Response).

+answer(Answer) : service(Answer, Service)	
	<- 	
		if (.substring("Agenda: ",Answer)){.send(agenda,achieve,say(Blex,Answer));}
		else {
		!doService(Service, Answer, Response);
		!showAnsw(Response); 
		+realizada(Answer, Response);	
		+recibida(Answer);
		}.
						 	 			
+answer(Answer) 	
	<- 	
		if (.substring("Agenda: ",Answer)){.send(agenda,achieve,say(Blex,Answer));}
		else {
		!showAnsw(Answer);
		+recibida(Answer);
		}.
