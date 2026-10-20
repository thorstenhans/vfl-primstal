import personPlaceholder from "../images/person-placeholder.png";

export interface VorstandMember {
  firstname: string;
  lastname: string;
  position: string;
  email: string;
  imageUrl: string;
  pinned?: boolean;
}

export const praesidium: VorstandMember[] = [
  {
    firstname: "Timo",
    lastname: "Horn",
    position: "Vorsitzender",
    email: "timo.horn@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
  },
  {
    firstname: "Thomas",
    lastname: "Paulus",
    position: "Vorsitzender",
    email: "thomas.paulus@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
  },
  {
    firstname: "Christoph",
    lastname: "Holz",
    position: "Vorsitzender",
    email: "christoph.holz@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
  },
];

export const members: VorstandMember[] = [
  {
    firstname: "Julius",
    lastname: "Wiesen",
    position: "Hauptkassier",
    email: "julius.wiesen@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: true,
  },
  {
    firstname: "Alwin",
    lastname: "Arm",
    position: "Spielausschussvorsitzender",
    email: "alwin.arm@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: true,
  },
  {
    firstname: "Franz-Josef",
    lastname: "Backes",
    position: "Jugendleiter",
    email: "franz-josef.backes@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: true,
  },
   {
    firstname: "Dietmar",
    lastname: "Scheid",
    position: "Pressewart",
    email: "dietmar.scheid@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: true,
  },
  {
    firstname: "Gerhard",
    lastname: "Rink",
    position: "Pressewart",
    email: "gerhard.rink@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Michael",
    lastname: "Arm",
    position: "Pressewart",
    email: "michael.arm@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Thorsten",
    lastname: "Gierend",
    position: "Orga-Team",
    email: "thorsten.gierend@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Mike",
    lastname: "Scharf",
    position: "Orga-Team",
    email: "mike.scharf@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Oliver",
    lastname: "Arm",
    position: "Orga-Team",
    email: "oliver.arm@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Tobias",
    lastname: "Wiesen",
    position: "Orga-Team",
    email: "tobias.wiesen@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Günter",
    lastname: "Zarth",
    position: "Beisitzer (Kassenwesen)",
    email: "guenter.zarth@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Christian",
    lastname: "Joseph",
    position: "Beisitzer (Jugend)",
    email: "christian.joseph@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Marco",
    lastname: "Ludwig",
    position: "Beisitzer",
    email: "marco.ludwig@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Thorsten",
    lastname: "Hans",
    position: "Orga-Team",
    email: "thorsten.hans@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Daniel",
    lastname: "Fuchs",
    position: "Orga-Team",
    email: "daniel.fuchs@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
  {
    firstname: "Sven",
    lastname: "Seimetz",
    position: "Orga-Team",
    email: "sven.seimetz@vfl-primstal.de",
    imageUrl: personPlaceholder.src,
    pinned: false,
  },
];
