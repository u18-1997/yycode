-- ---------------------------- 
-- yyget获得表内容，
-- 
--
--
-- -----------------------------
DELIMITER $$
CREATE PROCEDURE `yyget`(	in `tabName` varchar(50),
												in `sqlFileds` varchar(512),
												in `sqlWhere` varchar(512)
											 )
top:
BEGIN
	declare `@databasenow` varchar(255);
	declare`f1` varchar,declare`f2` varchar,declare`f3` varchar(64);
	declare `f0`,`vf0`,`v1`,`v2`,`v3`,`tempSqlFileds`,`tempSqlWhere`,`delimiter`,`@activeTable` varchar(1024);
	declare `symbol` varchar(1);
	declare done int;
	DECLARE `cursorfiled` CURSOR FOR select column_name,column_type,column_comment from information_schema.COLUMNS where TABLE_SCHEMA = @databasenow and TABLE_NAME= tabName;  	
	declare continue handler FOR SQLSTATE '02000' SET done = 1;  
	
	set @databasenow = (select database());
	set f0 = "";set vf0 = "";set v1 = "";set v2 = "";set v3 = "";set symbol="",delimiter="";
	drop table  if exists tempFieldTable;
	if not exists (select * from information_schema.COLUMNS where TABLE_SCHEMA = @databasenow and TABLE_NAME= tabName) then 
		
		select concat("这个表不存在，当前默认数据库:",@databasenow);
		leave top;	
	end if;
	open cursorfiled; 
	repeat
	 fetch cursorfiled into f1,f2,f3;
	  if done is null then 
		set f0=concat(f0,f1," varchar(64),");
		set vf0=concat(vf0,f1,",");
		set v1=concat(v1,"'",f1,"',");
		set v2=concat(v2,"'",f2,"',");
		set delimiter=concat(delimiter,"'","+++++++++++","',");
		if (v3!="") then 
			set symbol=","; 
		end if; 
		set v3=concat(v3,symbol,"'",f3,"'");
	  end if ;
	until done end repeat;
	close cursorfiled;
	set f0 = left(f0,LENGTH(f0)-1);
	set vf0 = left(vf0,LENGTH(vf0)-1);
	set v1 = left(v1,LENGTH(v1)-1);
	set v2 = left(v2,LENGTH(v2)-1);
	set delimiter=left(delimiter,length(delimiter)-1);

	set f0 = concat("create temporary table tempFieldTable (",f0,");");
	set @activeTable=f0;
	prepare temppeare from @activeTable;
	execute temppeare;

	set @activeTable = concat("insert into tempFieldTable (",vf0,")"," values (",v1,"),(",v2,"),(",v3,"),(",delimiter,")");
	prepare temppeare from @activeTable;
	execute temppeare;

	set tempSqlFileds="";
	set tempSqlWhere="";

	if (sqlFileds="" or sqlFileds="*") then 
		set tempSqlFileds=vf0;
    else				
		set tempSqlFileds=sqlFileds;
	end if;
	if sqlWhere!="" then 
		set tempSqlWhere = concat(" where ",sqlWhere);
	end if;
	 set @activeTable=concat("select ",tempSqlFileds," from tempFieldTable ",
							  " union all  "
							 , " select ",tempSqlFileds," from ",tabName,tempSqlWhere);

	
	 prepare temppeare from @activeTable;
	 execute temppeare;
	drop table tempFieldTable;
END
