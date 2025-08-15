var subprocess = require( "child_process" );
var readline = require( "readline" );
var fs = require( 'fs' );
var glob = require( 'glob' );

var chaser = 'D:\\gmod_servers\\gRTS\\garrysmod\\addons\\chaser';
var gmad = 'D:\\gmod_servers\\gRTS\\bin\\gmad.exe';
var steam = 'D:\\gserv\\steamcmd.exe';

function fi( dir, interests ) {

	var yes = 0, no = 0;
	var flagged = { };
	interests.forEach( v1 => {
		var files = fs.readdirSync( dir + v1 );
		files.forEach( value => {
			// console.log( "    " + value );
			
			files.forEach( fileName => {
				console.log( "Renaming... " + fileName + ", " + chaser + v1 );
				if ( !fs.existsSync( chaser + v1 ) ) {
					fs.mkdirSync( chaser + v1 );
				}

				var begin = dir + v1 + "\\" + value;
				if ( flagged[begin] ){
					console.log( "Skipping: " + begin );
				} else {
					try {
						
						fs.renameSync(dir + v1 + "\\" + value, chaser + v1 + "\\" +  value );
						yes++;
						console.log( "YES!" );
						flagged[begin] = true;
					} catch(e){
						no++;
						console.log( e );
					}
				}
			} );
		} );
	} );
	console.log( "Passed: " + yes );
	console.log( "Failed: " + no );
	console.log( "All done!" );
	console.log( "Cleaning up..." );
	fs.rmdirSync( __dirname + "\\extracted", { recursive: true, force: true } );
	fs.mkdirSync( __dirname + "\\extracted" );
	fs.rmdirSync( __dirname + "\\steamapps", { recursive: true, force: true } );
	
}
function merge( dir ) {
	let interests = [
		'\\lua\\entities',
		'\\materials\\entities',
	]
	fs.readdir( dir + "\\lua\\entities", ( err, files ) => {
		var npc = files[0].replace(/\.[^/.]+$/, "");
		interests.push( '\\sound\\' + npc );
		interests.push( '\\materials\\' + npc );
		fi( dir, interests );
	} );
}
function extract( fname ) {
	console.log( "Extracting from " + fname );
	var gmextract = subprocess.exec(
		gmad + " extract -file " + fname + " -out " + __dirname + "\\extracted",
		function( error, stdout, stderr ){
			console.log( stdout );
			console.log( "Merging files with addon..." );
			// merge( __dirname + "\\extracted" );
		}
	)
}
function parse( id ) {
	var dir = __dirname + "/steamapps/workshop/content/4000/" + id;
	glob( dir + "/*.gma", {}, (err, files) => {
		if ( files.length != 1 ) {
			console.log( 'wtf happened?', files );
			return;
		}

		var fname = files[0];
		extract(fname)
	} );
}

function handleExit( id ) {
	return function( _code ) {
		console.log( 'SteamCMD should be done, lets check our downloads.' );
		if ( fs.existsSync( __dirname + "/steamapps/workshop/content/4000/" + id ) ) {
			console.log( "Addon downloaded successfully." )
			return parse( id );
		} else {
			console.log( "Addon didn't download?" )
		}
	}
}

var rl = readline.createInterface({ input: process.stdin, output: process.stdout });
console.clear();
rl.question( `Enter the ID for the workshop addon: `, id => {
	rl.close();

	var num = Number( id )
	if ( Number.isInteger(num) && num > 0 ) {
		var steamcmd = subprocess.spawn( steam, [
			'+login anonymous',
			'+force_install_dir ' + __dirname,
			'+workshop_download_item 4000 ' + id,
			"+quit"
		] );
		steamcmd.on( 'data', console.log );
		steamcmd.on( 'exit', handleExit( id ) );
	} else {
		console.log( "Invalid workshop ID." );
	}
} );